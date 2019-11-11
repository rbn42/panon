import io
import numpy as np
from PIL import Image
import base64


class Numpy2Str:
    img_data_map = {}

    def convert(self, data):
        if data is None:
            return ''
        data_length, _ = data.shape
        key = data_length
        if self.img_data_map.get(key) is None:
            self.img_data_map[key] = np.zeros((1, data_length, 3), dtype='uint8')
        img_data = self.img_data_map[key]
        img_data[0, :, :2] = data

        image = Image.fromarray(img_data)
        data = io.BytesIO()
        image.save(data, "bmp")
        message = 'data:img/bmp;base64,' + base64.b64encode(data.getvalue()).decode()
        return message
