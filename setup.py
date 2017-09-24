from setuptools import setup
import glob

setup(
    name='panon',
    version='v0.1.1',
    description='A status bar for X window managers',
    url='http://github.com/rbn42/panon',
    download_url='https://github.com/rbn42/panon/archive/v0.1.1.tar.gz',
    author='rbn42',
    author_email='bl100@students.waikato.ac.nz',
    license='MIT',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Environment :: X11 Applications',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: GNU Affero General Public License v3',
        'Programming Language :: Python :: 3',
    ],
    keywords=['visualizer', 'multiload', 'panel', 'xorg'],
    packages=['panon','panon.visualizer','panon.glsl'],    
    package_data={ 
        'panon.glsl': ['*.vert','*.frag', "*.glsl"],
    },        
    install_requires=[
        #'docopt',
        'ewmh',
        'numpy',
        'pyaudio',
        'psutil',
        'python-xlib',
    ],
    data_files=[
        ('share/doc/panon/config', glob.glob('doc/config/*')),
    ],
    entry_points={
        'console_scripts': [
            'panon=panon.__main__:main',
        ]
    }
)
