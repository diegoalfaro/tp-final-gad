from fastapi import FastAPI, Request, Form, File, UploadFile
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import uuid

from . import db, utils, config

utils.makedirs(config.paths['received_images'])
utils.makedirs(config.paths['search_images'])

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="/static"), name="static")

@app.get("/")
def root():
    try:
        status = db.check_status()
        return {"status": status }
    except:
        return {"status": False }

"""***********************
* Artworks endpoints     *
***********************"""

@app.get("/artworks")
def get_all_artworks(request: Request):
    url_prefix = utils.get_url_prefix_from_request(request)
    return db.get_all_artworks(url_prefix)

@app.post("/artworks")
def add_artwork(request: Request, title: str = Form(), artist_id: int = Form(), image: UploadFile = File(...)):
    url_prefix = utils.get_url_prefix_from_request(request)
    filepath = Path(f"{config.paths['received_images']}{uuid.uuid4()}.jpg")
    utils.save_upload_file(image, filepath)
    resized_image = utils.resize_image(filepath, (200, 200)) #io.BytesIO(image.file.read())
    return db.insert_artwork(title, artist_id, str(filepath), resized_image, url_prefix)

@app.get("/artworks/random")
def get_artworks_random(request: Request, limit: int = 20):
    url_prefix = utils.get_url_prefix_from_request(request)
    return db.get_artworks_random(limit, url_prefix)

@app.get("/artworks/{artwork_id}")
def get_artwork_by_id(request: Request, artwork_id: int):
    url_prefix = utils.get_url_prefix_from_request(request)
    return db.get_artwork(artwork_id, url_prefix)

@app.get("/artworks/similar/{artwork_id}")
def get_similar_artworks_by_artwork_id(request: Request, artwork_id: int, radius: int = 10, limit: int = 20):
    url_prefix = utils.get_url_prefix_from_request(request)
    return db.get_similar_artworks(artwork_id, limit, radius, url_prefix)

@app.post("/artworks/similar")
def get_similar_artworks_by_artwork_data(request: Request, image: UploadFile = File(...), radius: int = 10, limit: int = 20):
    url_prefix = utils.get_url_prefix_from_request(request)
    filepath = Path(f"{config.paths['search_images']}{uuid.uuid4()}.jpg")
    utils.save_upload_file(image, filepath)
    resized_image = utils.resize_image(filepath, (200, 200))
    return db.get_similar_artworks(resized_image, radius, limit, url_prefix)

"""***********************
* Artists endpoints      *
***********************"""

@app.get("/artists")
def get_artists():
    return db.get_all_artists()

@app.get("/artists/{artist_id}")
def get_artist(artist_id: int):
    return db.get_artist(artist_id)

"""***********************
* Pivots endpoints       *
***********************"""

@app.get("/pivots")
def get_pivots():
    return db.get_all_pivots()
