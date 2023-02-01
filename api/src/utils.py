import os
import io
import shutil
from pathlib import Path
from fastapi import UploadFile
from PIL import Image

def makedirs(dirs):
    os.makedirs(dirs, mode=0o777, exist_ok=True)

def get_url_prefix_from_request(request, path=''):
    return '%s://%s:%s%s' % (request.url.scheme, request.url.hostname, request.url.port, path)

def resize_image(fp, dimensions):
    image = Image.open(fp) # Image.frombytes(io.BytesIO(image.file.read()))
    resized = image.resize(dimensions)
    converted = resized.convert('RGB')
    b = io.BytesIO()
    converted.save(b, 'jpeg')
    im_bytes = b.getvalue()
    return im_bytes

def save_upload_file(upload_file: UploadFile, destination: Path):
    with destination.open("wb") as buffer:
        os.chmod(destination, 0o0777)
        shutil.copyfileobj(upload_file.file, buffer)
