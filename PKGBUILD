pkgname=panon-git
pkgver=0.1.0
pkgrel=1
pkgdesc="A Different Audio Spectrum Analyzer"
arch=('any')
url="http://github.com/rbn42/panon"
license=('GPL3')
depends=('plasma-workspace' 'python-numpy' 'python-pillow' 'python-pyaudio' 'python-websockets' 'qt5-websockets' 'qt5-3d') 
makedepends=('git')
provides=('panon')
conflicts=('panon')
source=("$pkgname::git+https://github.com/rbn42/panon")
md5sums=('SKIP')

pkgver() {
  cd "$srcdir/$pkgname"
  git describe --always | sed -e 's|-|.|g' -e '1s|^.||'
}

package() {
  cd "$srcdir/$pkgname"
  #python setup.py install --root "$pkgdir"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/${pkgname%-*}/LICENSE"

  cd kde
  kpackagetool5 -p "$pkgdir/usr/share/plasma/plasmoids/" -t Plasma/Applet -i plasmoid
  rm "$pkgdir/usr/share/plasma/plasmoids/kpluginindex.json"
}

