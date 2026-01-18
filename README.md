#  Image Decompressor

Image Decompressor is a hardware-based project implemented in Verilog to perform lossless decoding, dequantization, inverse signal transformation, interpolation, and color space conversion. The system runs on FPGA hardware, using Quartus for simulation, timing analysis, and deployment, and is capable of reconstructing compressed images in real time.

##  Features

-  **Upsampling & Colour Space Conversion (M1)**                         
  Converts YUV to RGB using interpolation and color space conversion with ~76% multiplier utilization.
  
-  **Inverse Discrete Cosine Transform (M2)**             
  Implements IDCT with multiple DPRAMs to fetch, multiply, and store coefficients, reconstructing image data from frequency space to pixel space.
  
-  **Lossless Decoding & Dequantization**               
  Supports reverse-engineering of compressed image data into raw pixel values.
  
-  **SRAM & DPRAM Integration**          
  Efficient read/write operations to handle pixel blocks for real-time decompression.        
-  **Modular FSM Design**             
  Each stage (Fs, Ct, Cs, Ws) runs as an independent state machine for parallelism and clarity.           

##  Tech Stack

-  **Hardware & Components**     
  FPGA (Quartus, Verilog HDL)    
  Dual-Port RAMs (DPRAM), shift registers, multiplexers, counters, FIR multipliers
  
- **Tools**    
  Quartus Prime    
  ModelSim 
  Git    

##  Performance Metrics

- **Milestone 1 (Colour Space + Upsampling):**
  - ~273,600 clock cycles to complete per image row set.
  - Achieved ~75% multiplier utilization.
  - 1267 logic elements used.
- **Milestone 2 (IDCT):**
  - ~1,257,600 total clock cycles to complete for Y, U, and V segments.
  - 2101 additional logic elements, bringing total usage to ~3698 (as estimated by Quartus).
- **Overall:**
  - ~3.4x increase in resource utilization from baseline, demonstrating the cost of IDCT operations in hardware.

## Future Improvements

- Simplify lead-in states in M1 by reducing from 21 states to 14 for better efficiency.
- Optimize coefficient MUX design by cutting down unnecessary entries to reduce logic usage.
- Improve Calc S state to include clipping/scaling before storage, minimizing wasted register bits.
- Fully debug IDCT stage mismatches at block boundaries for 100% decompression accuracy.

