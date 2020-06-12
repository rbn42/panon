import numpy as np
#import io
#from PIL import Image
import base64


class Numpy2Str:
    img_data_map = {}

    def convert(self, data):
        return self.new_convert(data)

    def new_convert(self, data):
        if data is None:
            return ''
        body = self.get_body(data)
        head = self.get_head(len(body), data.shape[0])
        message = 'img/bmp;base64,' + base64.b64encode(head + body).decode()
        return message

    def get_head(self, body_size, width):
        return b'BM' + (54 + body_size).to_bytes(4, 'little') +\
                b'\x00\x00\x00\x006\x00\x00\x00(\x00\x00\x00' + width.to_bytes(4, 'little') +\
                b'\x01\x00\x00\x00\x01\x00\x18\x00\x00\x00\x00\x00' + body_size.to_bytes(4, 'little') +\
                b'\xc4\x0e\x00\x00\xc4\x0e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    def get_body(self, data):
        data_length, _ = data.shape
        key = data_length
        if self.img_data_map.get(key) is None:
            self.img_data_map[key] = np.zeros((1, data_length, 3), dtype='uint8')
        img_data = self.img_data_map[key]
        img_data[0, :, :2] = data
        data = img_data[:, :, ::-1].tobytes()
        return data + b'\x00' * ((4 - len(data)) % 4)

    def old_convert(self, data):
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
        message = 'img/bmp;base64,' + base64.b64encode(data.getvalue()).decode()
        return message
