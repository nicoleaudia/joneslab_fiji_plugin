import os
# os.environ["CUDA_VISIBLE_DEVICES"]="1"
import numpy as np
from natsort import natsorted
from microsam_plugin_helper import *
import sys

print('Imported all functions.')

if torch.backends.mps.is_available():
    device = torch.device("mps")
elif torch.cuda.is_available():
    device = torch.device("cuda")
else:
    device = torch.device("cpu")
    # NOTE: AMD GPUs(on Windows)nare not supported by PyTorch


def main():
    print ('Starting micro_sam plugin.')

    if len(sys.argv) > 3:
        model_id = sys.argv[1]
        bf_dir = sys.argv[2]
        segmentation_dir = sys.argv[3]
    else:
        raise ValueError("Arguments missing. Usage: python script.py <model_id> <bf_dir> <segmentation_dir>")

    ########## USER INPUT ##########
    # model_id = "finetuned_vit_l"
    usam_lm_algorithm = None # 'amg', 'ais', or None. Should be None for finetuned models
    acceptable_file_types = (".tif", ".tiff", ".TIF", ".TIFF")

    # Throw an error if the bf_dir directory doesn't exist or is empty (either needs to be created by user or macro)
    if not os.path.exists(bf_dir):
        raise ValueError(f"Directory {bf_dir} does not exist.")
    if not os.listdir(bf_dir):
        raise ValueError(f"Directory {bf_dir} is empty.")

    # Create the segmentation_dir directory if it doesn't exist
    os.makedirs(segmentation_dir, exist_ok=True)

    ########## ^USER INPUT ##########

    # Load checkpoint based on model_id
    if model_id == "finetuned_vit_b":
        checkpoint_path = '/Applications/Fiji.app/plugin_dir/vit_b_weightsonly.pt'
        pred_iou_thresh = 0.425
        stability_score_thresh = 0.65
    elif model_id == "finetuned_vit_b_lm":
        checkpoint_path = '/Applications/Fiji.app/plugin_dir/vit_b_lm_weightsonly.pt'
        pred_iou_thresh = 0.4
        stability_score_thresh = 0.5
    elif model_id == "finetuned_vit_l":
        checkpoint_path = '/Applications/Fiji.app/plugin_dir/vit_l_weightsonly.pt'
        pred_iou_thresh = 0.8
        stability_score_thresh = 0.725
    elif model_id == "finetuned_vit_l_lm":
        checkpoint_path = '/Applications/Fiji.app/plugin_dir/vit_l_lm_weightsonly.pt'
        pred_iou_thresh = 0.45
        stability_score_thresh = 0.675
    else:
        checkpoint_path = None
        pred_iou_thresh = 0.75
        stability_score_thresh = 0.75

    # Only need option for finetuned ViT model - PHANTAST will be handled by macro, other models not available
    if "vit_" in model_id:
        filenames = natsorted([f for f in os.listdir(bf_dir) if f.endswith(acceptable_file_types)])
        batch_size = 3
        
        # Segment the images
        normalised_segmentations = process_images_in_batches(filenames=filenames, batch_size=batch_size, bf_dir=bf_dir, model_choice=model_id, usam_lm_algorithm=usam_lm_algorithm, checkpoint_path=checkpoint_path, pred_iou_thresh=pred_iou_thresh, stability_score_thresh=stability_score_thresh)
      
        print(f"Normalised segmentations stack has length: {len(normalised_segmentations)}.")
        normalised_segmentations = np.array(normalised_segmentations) 
    
        # save_images_as_stack(directory=segmentation_dir, input_images=normalised_segmentations, filename="Mask_Stack.tiff")
        save_indv_images(normalised_segmentations, segmentation_dir, "segmentation")

        print(f"Saved individual segmentations to {segmentation_dir}.")

    else:
        # Throw an error
        raise ValueError(f"Model {model_id} not supported.")
    
    print ('Micro_sam plugin closing.')

if __name__ == "__main__":
    main()
