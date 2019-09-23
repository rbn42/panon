from setuptools import setup

setup(
    name='panon',
    version='v0.2.1',
    description='A Different Audio Spectrum Analyzer',
    url='http://github.com/rbn42/panon',
    download_url='https://github.com/rbn42/panon/archive/v0.2.1.tar.gz',
    author='rbn42',
    author_email='',
    license='GPLv3',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: GNU Affero General Public License v3',
        'Programming Language :: Python :: 3',
    ],
    keywords=['visualizer', 'spectrum', 'plasmoid'],
    packages=['panon'],    
    zip_safe=False,
    install_requires=[
        'numpy',
        'pyaudio',
        'websockets',
    ]
)
