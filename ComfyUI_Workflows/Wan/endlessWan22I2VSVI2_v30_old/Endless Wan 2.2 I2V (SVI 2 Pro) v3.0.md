
## [Endless Wan 2.2 I2V (SVI 2 Pro)](https://civitai.red/models/2701632/endless-wan-22-i2v-svi-2-pro)

![Endless Wan 2.2 I2V_v3.0.png](Endless_Wan_2.2_I2V_v3.0.png)


A simple workflow to create Wan 2.2 videos of unlimited duration, using SVI 2.0 Pro.  



- The workflow has a 5 sec "Initial" block and 8 more optional "Extend" blocks of 5 sec each that can create almost 45 sec of video  (some frames are lost in the connection).

- If more seconds than the ~45 provided are needed, you can copy an "Extend" block, connect it with the others and continue..

- The video generation can starts either from an initial image, or from an already existing video.

- Every block has its own Prompt selector and Length control in seconds (don't use more than 5.0).

- Every block has a fixed noise seed number, that lets you experiment with that block without re-generate all the previous, already generated blocks. You generate the video until that block, and if you're satisfied and need more time, you enable the next one. After that, *only the next one* will be generated (if you don't change something in the previous blocks or the LoRAs).

- ~~There are 3 LoRA sections. The Main (mandatory), the Extra 1 and the Extra 2 (for both High and Low models channels). All blocks are using the Main section, but you can choose if a block will use one of the Extra LoRAs or not.~~ (not after v3.0)

- Every block has its own independent LoRA section in addition to the Main LoRA section.

- Select between `GGUF loaders` for low VRAM systems or `Safetensors loaders` (didn't test the safetensors, but they should work).

- Accelerated Generation: Supports deeply optimized, distilled LoRAs (like Wan-Lightning) that generate high-quality video in as few as 4 steps using lightx2v 4-step LoRA.
  
- <ins>Warning: The LoRAs already loaded in the Main LoRA section are mandatory</ins> (for 4-steps & Linked blocks), except for the `Wan2.1_I2V_14B_FusionX_LoRA` that is there to speed up the movements.  
  If you don't need extra speed you can turn its value lower or turn it off entirely.

- <ins>Warning: If the workflow in your system does not look like the screenshot I provide</ins>, that means that you are using a more current, but unfortunately broken version of comfyui-frontend.. (You can search google for the subgraph issues with the 1.4x.xx releases of their frontend).   The last frontend version, that the subgraphs were working OK for me, was 1.39.2.
  To install this version, you must do `pip install comfyui-frontend-package==1.39.2` in your `..\venv\Scripts\` folder.
  After that you will see a warning once, but other than that, everything will work fine..

#### Version 3.0

- Added independent LoRA per (5sec) video section.
- Removed Extra LoRA 1/2 sections.

#### Version 2.5.1

- Added the option to extend already existing videos.
- Removed some leftover Crystools nodes so, no more compatibility problems with the RTX 50xx cards.
- Tried to fix the "missing prompts" problem.

#### Version 2.1

- Added another extra LoRA section to select from, in every 5 sec block.
- Speed additions to counteract the slow-motion effect a little: 
  - Changed the `HIGH_lightx2v_4step_lora_260412` with the `HIGH_lightx2v_4step_lora_v1030` because it has more coarse movements. You can change the strength from 1.0 to 1.5.
  - Added the `Wan2.1_I2V_14B_FusionX_LoRA` (to the high noise path only), that gives additional speed in the movements. Use a strength of 2.0 to 3.0.  
    This LoRA was created for the Wan2.1 model but works fine with Wan2.2 too. It produces a lot of warnings in the console for missing keys. This is because Wan2.2 misses some Wan2.1 keys, but it is just a warning nothing more. The generation works fine.  
    For those of you that want to fix this in the code of ComfyUI, you can rename the `logging.warning("lora key not loaded: {}".format(x))` line in the `ComfyUI\comfy\lora.py` file, to `logging.debug("lora key not loaded: {}".format(x))` (always backup your files before editing them, for safety).

#### Models used:
- [Wan2.2-I2V-A14B-HighNoise-Q4_K_S.gguf](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/blob/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q4_K_M.gguf)
- [Wan2.2-I2V-A14B-LowNoise-Q4_K_S.gguf](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/blob/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q4_K_M.gguf)
- [SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors](https://huggingface.co/Kijai/WanVideo_comfy/blob/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors)
- [SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors](https://huggingface.co/Kijai/WanVideo_comfy/blob/main/LoRAs/Stable-Video-Infinity/v2.0/SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors)
- [Wan_2_2_I2V_A14B_HIGH_lightx2v_4step_lora_v1030_rank_64_bf16.safetensors](https://huggingface.co/Kijai/WanVideo_comfy/blob/main/LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_4step_lora_v1030_rank_64_bf16.safetensors)
- [Wan_2_2_I2V_A14B_LOW_lightx2v_4step_lora_260412_rank_64_fp16.safetensors](https://huggingface.co/Kijai/WanVideo_comfy/blob/main/LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_LOW_lightx2v_4step_lora_260412_rank_64_fp16.safetensors)
- [Wan2.1_I2V_14B_FusionX_LoRA.safetensors](https://huggingface.co/vrgamedevgirl84/Wan14BT2VFusioniX/blob/main/FusionX_LoRa/Wan2.1_I2V_14B_FusionX_LoRA.safetensors)
- [umt5-xxl-encoder-Q3_K_S.gguf](https://huggingface.co/city96/umt5-xxl-encoder-gguf/blob/main/umt5-xxl-encoder-Q3_K_S.gguf)
- [wan_2.1_vae.safetensors](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/blob/main/VAE/Wan2.1_VAE.safetensors)

#### Custom Nodes used:

- [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)
- [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts)
- [ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes)
- [ComfyUI-Easy-Use](https://github.com/yolain/ComfyUI-Easy-Use)
- [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite)
- [ComfyUI-JakeUpgrade](https://github.com/jakechai/ComfyUI-JakeUpgrade)
- [rgthree-comfy](https://github.com/rgthree/rgthree-comfy)





