from PIL import ImageGrab
import pytesseract
import pyperclip

image = ImageGrab.grabclipboard()

if isinstance(image, list):  
    image = Image.open(image[0])  

text = pytesseract.image_to_string(image)
pyperclip.copy(text)

# sudo apt-get update
# sudo apt-get install tesseract-ocr
# pip3 install pytesseract --break-system-package
# sudo mv image_grab.py /usr/local/bin/image_grab
# sudo chmod +x /usr/local/bin/image_grab

# go to keyboard configuration and set this comand:
# python3 /usr/local/bin/image_grab

# -subfinder -d doit.com -all -recursive