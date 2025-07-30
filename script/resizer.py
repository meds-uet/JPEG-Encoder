# Copyright 2025 Maktab-e-Digital Systems Lahore.
# Licensed under the Apache License, Version 2.0, see LICENSE file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Description:
# This Python snippet uses the PIL (Pillow) library to open an image from a specified file path,
#  convert it to RGB format, resize it to 96×96 pixels (if not already that size), and optionally display it in the default image viewer. 
# Author:Navaal Noshi
# Date:30th July,2025

from PIL import Image
# Use full path to where you saved the image
image_path = r"C:\Users\HH Traders\Desktop\sample.jpg"
# Open and resize (optional if already 96x96)
img = Image.open(image_path).convert("RGB").resize((96, 96))
img.show()  # Optional: displays image
