FROM adoptopenjdk/openjdk12:alpine

LABEL maintainer="y.sogabe <y.sogabe@gmail.com>" \
      description="Pandoc for Japanese based on Alpine Linux. with PlantUML, pandocfilter"

ENV LANG=C.UTF-8
# Install Tex Live
ENV TEXLIVE_VERSION 2021
ENV PATH /usr/local/texlive/$TEXLIVE_VERSION/bin/x86_64-linuxmusl:$PATH

RUN apk --no-cache add perl wget xz tar fontconfig-dev \
 && mkdir -p /tmp/src/install-tl-unx \
 && wget -qO-  http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz | \
    tar -xz -C /tmp/src/install-tl-unx --strip-components=1 \
 && printf "%s\n" \
      "selected_scheme scheme-basic" \
      "option_doc 0" \
      "option_src 0" \
      > /tmp/src/install-tl-unx/texlive.profile \
 && /tmp/src/install-tl-unx/install-tl \
      --profile=/tmp/src/install-tl-unx/texlive.profile \
 && tlmgr option repository http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet \
 && wget http://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh \
 && chmod +x update-tlmgr-latest.sh \
 && tlmgr update --self && tlmgr update --all \
 && tlmgr install \
      collection-basic collection-latex \
      collection-latexrecommended collection-latexextra \
      collection-fontsrecommended collection-langjapanese latexmk \
      luatexbase ctablestack fontspec luaotfload lualatex-math \
      sourcesanspro sourcecodepro \
 && rm -Rf /tmp/src \
 && apk --no-cache del xz tar fontconfig-dev

# Install Pandoc
ENV PANDOC_VERSION 2.7.2
ENV PANDOC_DOWNLOAD_URL https://github.com/jgm/pandoc/archive/$PANDOC_VERSION.tar.gz
ENV PANDOC_DOWNLOAD_SHA512 4b3a21cf76777ed269bf7c13fd09ab1d5c97ed21ec9f02bff95fd3641ac9d52bde19a6e2ffb325378e611dfbe66b8b00769d8510a8b2fb1dfda8062d79b12233
ENV PANDOC_ROOT /usr/local/pandoc
ENV PATH $PATH:$PANDOC_ROOT/bin

# See https://github.com/lierdakil/pandoc-crossref 
RUN apk add --no-cache \
    gmp \
    libffi \
 && apk add --no-cache --virtual build-dependencies \
    --repository "http://nl.alpinelinux.org/alpine/edge/community" \
    ghc \
    cabal \
    linux-headers \
    musl-dev \
    zlib-dev \
    curl \
 && cabal new-update \
 && cabal new-install --global \
    pandoc pandoc-crossref pandoc-citeproc \
 && cp /root/.cabal/bin/* /usr/local/bin \
 && apk del --purge build-dependencies

 # Install plantuml
ENV PLANTUML_VERSION 1.2021.11
RUN apk add --no-cache \
    curl \
    graphviz \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family \
 && mkdir -p /usr/share/plantuml \
 && curl -o /usr/share/plantuml/plantuml.jar -JLsS \
    http://sourceforge.net/projects/plantuml/files/plantuml.${PLANTUML_VERSION}.jar/download \
 && ln -s /usr/local/texlive/2019/texmf-dist/fonts/truetype/public/ipaex /usr/share/fonts/ipa \
 && fc-cache -fv \
 && apk del --purge curl

# Install pandocfilters
RUN apk --no-cache add \
    git \
    python2 \
 && cd /tmp \
 && git clone https://github.com/jgm/pandocfilters.git \
 && cd /tmp/pandocfilters \
 && python setup.py install \
 && sed 's/plantuml.jar/\/usr\/share\/plantuml\/plantuml.jar/' examples/plantuml.py \ 
     > /usr/share/plantuml/plantuml.py \
 && sed -i.bk 's/latex=\"eps\"/latex=\"png\"/' /usr/share/plantuml/plantuml.py \
 && rm -rf /usr/share/plantuml/plantuml.py.bk \
 && rm -rf /tmp/pandocfilters \
 && chmod +x /usr/share/plantuml/plantuml.py \
 && apk del --purge git

VOLUME ["/workspace", "/root/.pandoc/templates"]
WORKDIR /workspace
