import numpy as np
import os
import tifffile as tiff
import torch
import json

# from micro_sam import util
from micro_sam import util
from micro_sam.instance_segmentation import (
    AutomaticMaskGenerator,
    mask_data_to_segmentation
)

from micro_sam.training.util import TrainableSAM


def preprocess_image(image):
    """Convert image to float64 and normalise to [0, 255] range."""
    im = image.astype(np.float64)
    im -= im.min()
    im /= (im.max() + 1e-6)  # Avoid division by zero
    im *= 255
    im = np.clip(im, 0, 255)
    return im

def normalise_ml_stack(segmentation_stack):
    normalised_stack = []
    for image in segmentation_stack:
        # Normalise and convert the image to binary
        normalised_image = (image / np.max(image) > 0).astype(np.uint8)
        normalised_stack.append(normalised_image)
    return normalised_stack # return in list form


# NMA: edited this function from micro_sam
def run_automatic_mask_generation(image, model_type="vit_b", checkpoint_path=None, pred_iou_thresh=0.75, stability_score_thresh=0.75):
    """Automatic Mask Generation using a fine-tuned model.
    
    NOTE: It is supported for both Segment Anything models and µsam models.
    
    Args:
        image: The input image.
        model_type: The choice of the `SAM` / `µsam` model.
        checkpoint_path: Path to the fine-tuned model checkpoint.

        NMA NOTE: added pred_iou_thresh and stability_score_thresh args
        
    Returns:
        The instance segmentation.
    """

    print(f"Making prediction with pred_iou_thresh = {pred_iou_thresh} and stability_score_thresh = {stability_score_thresh}.")
    # Step 1: Initialize the model attributes using the pretrained or fine-tuned SAM / µsam model weights.
    predictor = util.get_sam_model(
        model_type=model_type, 
    )

    # NMA NOTE: CHANGED THIS 9/5
    if hasattr(predictor, 'model'):
        # Load the fine-tuned model weights if a checkpoint path is provided
        if checkpoint_path is not None:
            checkpoint = torch.load(checkpoint_path, map_location=torch.device("cuda" if torch.cuda.is_available() else "cpu"))
            
            # Check if checkpoint is a TrainableSAM instance
            if isinstance(checkpoint, TrainableSAM):
                # Extract the state_dict from the TrainableSAM object
                state_dict = checkpoint.sam.state_dict()  # Extract the actual weights
            else:
                state_dict = checkpoint  # If it's already a state_dict

            # Load the extracted state_dict into the model
            predictor.model.load_state_dict(state_dict)
    else:
        print("No internal model found to load state_dict into.")

    # Step 2: Computation of the image embeddings from the vision transformer-based image encoder.
    image_embeddings = util.precompute_image_embeddings(
        predictor=predictor,  
        input_=image,  
        ndim=2,  
    )
    
    # Step 3: Initializing the predictor for automatic mask generation.
    amg = AutomaticMaskGenerator(predictor)
    
    # Step 4: Initializing the precomputed image embeddings to perform automatic segmentation using automatic mask generation.
    amg.initialize(
        image=image,  
        image_embeddings=image_embeddings, 
    )
    
    # Step 5: Getting automatic instance segmentations for the given image and applying the relevant post-processing steps.
    print(f"Generating list of instance segmentations (masks) for image with shape: {image.shape}. dtype: {image.dtype}, max: {image.max()}")
    prediction = amg.generate( 
        pred_iou_thresh=pred_iou_thresh,
        stability_score_thresh=stability_score_thresh 
    )
    
    # NMA NOTE: similiarly converts to np zeros uint32
    # NMA: adding this in to account for images where no segmentation can be found
    if len(prediction):
        prediction = mask_data_to_segmentation(prediction, with_background=False)
    else:
        prediction = np.zeros_like(image, dtype=np.uint32)

    # # Optional: plot
    # plt.imshow(prediction, cmap='gray') 
    # plt.title("(^Prediction outputted by mask_data_to_segmentation)")
    # plt.show()
    return prediction



def process_images_in_batches(filenames, batch_size, bf_dir, model_choice, usam_lm_algorithm=None, checkpoint_path=None, pred_iou_thresh=0.75, stability_score_thresh=0.75):
    segmentations = []
    for batch_start in range(0, len(filenames), batch_size):
        batch_end = min(batch_start + batch_size, len(filenames))
        batch_filenames = filenames[batch_start:batch_end]

        for filename in batch_filenames:
            filepath = os.path.join(bf_dir, filename)
            tiff_img = tiff.imread(filepath)
            
            print(f"Processing {filename} via {model_choice}.")
            raw = preprocess_image(tiff_img)

            if usam_lm_algorithm == 'amg' or usam_lm_algorithm == None:

                # If finetuned model, temporarily rename in order to pass in base model
                if model_choice.startswith("finetuned_"):
                    model_choice = model_choice.replace("finetuned_", "")
                    print(f"Temporarily renaming the finetuned model to {model_choice}.")

                # Make prediction
                prediction = run_automatic_mask_generation(raw, model_type=model_choice, checkpoint_path=checkpoint_path, pred_iou_thresh=pred_iou_thresh, stability_score_thresh=stability_score_thresh)

            # NMA: removing option for AIS
            else:
                raise ValueError(f"Invalid usam_lm_algorithm, can only be None in plugin: {usam_lm_algorithm}.")
            # else:
            #     # Make prediction
            #     prediction = run_automatic_instance_segmentation(raw, model_type=model_choice)

            print(f"Processed {filename} via {model_choice}.")

            segmentations.append(prediction)
            print(f'Working segmentations list has length: {len(segmentations)}.')

        
    # Normalise stack
    normalised_segmentations = normalise_ml_stack(segmentations)    
    print(f"Normalised segmentations list has length: {len(normalised_segmentations)}")

    # Return as list
    return normalised_segmentations

def load_thresholds(model_id, thresholds_dir='thresholds'):
    """
    Load threshold values based on the model type.

    Args:
        model_type (str): The type of model (e.g., 'finetuned_vit_b', 'finetuned_vit_l').
        thresholds_dir (str): Directory where threshold files are stored.

    Returns:
        tuple: A tuple containing thresh1 and thresh2 values.
    """

    # Check model is valid
    finetuned_models = ['finetuned_vit_b', 'finetuned_vit_b_lm', 'finetuned_vit_l', 'finetuned_vit_l_lm']
    if model_id not in finetuned_models:
        raise ValueError(f"Error: '{model_id}' is not a valid model type. Please choose from {finetuned_models}.")

    # Get the filename
    threshold_file = os.path.join(thresholds_dir, f"{model_id}_thresholds.json")

    if not os.path.exists(threshold_file):
        raise FileNotFoundError(f"Threshold file for model type '{model_id}' not found at {threshold_file}.")

    # Load the thresholds from the file
    with open(threshold_file, 'r') as f:
        thresholds = json.load(f)

    pred_iou_thresh = thresholds.get('pred_iou_thresh', 0.75)  # Default to 0.75 if not found
    stability_score_thresh = thresholds.get('stability_score_thresh', 0.75)  # Default to 0.75 if not found

    return pred_iou_thresh, stability_score_thresh


# from utils.stack_manipulation_utils
def save_images_as_stack(directory, input_images, filename):
    output_path = os.path.join(directory, filename)
    tiff.imwrite(output_path, input_images, photometric='minisblack')
    print(f"Saved stack of {input_images.shape[0]} images to {output_path}")


def save_indv_images(image_stack, directory, base_filename):
    os.makedirs(directory, exist_ok=True)
    for idx, image in enumerate(image_stack):
        filename = os.path.join(directory, f"{base_filename}_{idx:04d}.tiff")
        tiff.imwrite(filename, image)