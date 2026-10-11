import base64
import struct

import numpy as np


class Numpy2Str:
    """
    Converts audio data to data URIs of 1-pixel-high BMP images,
    so that they can be used as textures by the shaders.
    """

    def __init__(self):
        # Reusable image buffers, indexed by the image width.
        self.img_data_map = {}

    def convert(self, data):
        body = self._body(data)
        head = self._head(len(body), data.shape[0], 1)
        return 'image/bmp;base64,' + base64.b64encode(head + body).decode()

    def _head(self, body_size, width, height):
        header_size = 14 + 40
        # BITMAPFILEHEADER: signature, file size, reserved, offset of the pixel data
        file_header = struct.pack('<2sIHHI', b'BM', header_size + body_size, 0, 0, header_size)
        # BITMAPINFOHEADER: header size, width, height, planes, bits per pixel, no compression,
        # image size, horizontal and vertical resolution (96 DPI), colors in palette, important colors
        info_header = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 24, 0, body_size, 3780, 3780, 0, 0)
        return file_header + info_header

    def _body(self, data):
        data_length, _ = data.shape
        if data_length not in self.img_data_map:
            self.img_data_map[data_length] = np.zeros((1, data_length, 3), dtype='uint8')
        img_data = self.img_data_map[data_length]
        img_data[0, :, :2] = data
        data = img_data[:, :, ::-1].tobytes()
        return data + b'\x00' * ((4 - len(data)) % 4)
