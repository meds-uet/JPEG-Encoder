# Copyright 2025 Maktab-e-Digital Systems Lahore.
# Licensed under the Apache License, Version 2.0, see LICENSE file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description:
# This Python script converts an RGB image (specifically resized to 96×96 pixels) into a SystemVerilog-compatible stimulus file
# by extracting the red, green, and blue values of each pixel and formatting them as 24-bit binary values, where blue occupies bits [23:16], green [15:8], 
# and red [7:0]. Each line in the output file assigns a pixel to the data_in signal in the format data_in <= 24'b...; followed by a delay (#10000;),
# making it suitable for use in a Verilog or SystemVerilog testbench for simulating an image-processing module like a JPEG encoder.
#
# Author:Navaal Noshi
# Date:30th July,2025

from PIL import Image
import os

def image_to_sv_binary(image_path, output_path="image_input_bin.sv", delay="#10000"):
    # Open the image, convert to RGB, and resize to 96x96
    img = Image.open(image_path).convert("RGB").resize((96, 96))
    
    # Get all pixels as a flat list of (R, G, B) tuples
    pixels = list(img.getdata())

    with open(output_path, 'w') as f:
        for r, g, b in pixels:
            # Correct bit placement: B [23:16], G [15:8], R [7:0]
            binary_val = f"{b:08b}{g:08b}{r:08b}"
            f.write(f"data_in <= 24'b{binary_val}; {delay};\n")

    print(f" SystemVerilog binary file generated: {output_path}")

# Set your input and output file paths here
desktop_path = r"C:\Users\HH Traders\Desktop\image.TIFF"
output_sv_file = r"C:\Users\HH Traders\Desktop\image_input_bin.sv"

# Run the conversion
image_to_sv_binary(desktop_path, output_sv_file)


