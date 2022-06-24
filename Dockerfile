FROM alpine:3.15 as builder

LABEL MAINTAINER='dogbutcat@hotmail.com'

ENV ARIA2_VERSION 1.36.0
ENV GNUTLS_MAIN_VERSION 3.6
ENV GNUTLS_VERSION 3.6.16
ENV P11_VERSION 0.24.1
ENV TASN_VERION 4.18.0
ENV LIBTASN1=http://ftp.gnu.org/gnu/libtasn1/libtasn1-${TASN_VERION}.tar.gz
ENV P11=https://github.com/p11-glue/p11-kit/releases/download/${P11_VERSION}/p11-kit-${P11_VERSION}.tar.xz
ENV GNUTLS=https://www.gnupg.org/ftp/gcrypt/gnutls/v${GNUTLS_MAIN_VERSION}/gnutls-${GNUTLS_VERSION}.tar.xz
ENV ARIA2=https://github.com/aria2/aria2/releases/download/release-${ARIA2_VERSION}/aria2-${ARIA2_VERSION}.tar.gz
WORKDIR /opt/builder

# dynamic build setting
# RUN apk add gnutls-dev nettle-dev gmp-dev g++ make \
# 	libssh2-dev c-ares-dev expat-dev zlib-dev sqlite-dev pkgconfig

# static build setting
RUN apk add openssl-libs-static libgcrypt-static libgcrypt-dev libunistring-static libunistring-dev \
	nettle-static nettle-dev gmp-dev g++ make binutils \
	libssh2-static libssh2-dev c-ares-static c-ares-dev expat-static expat-dev zlib-static zlib-dev \
	sqlite-static sqlite-dev pkgconfig xz

# deps for build libtasn1
RUN apk add libffi-dev

RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/:/lib:/usr/glibc-compat/lib
RUN export LIBRARY_PATH=$LIBRARY_PATH:/usr/lib/:/lib:/usr/glibc-compat/lib

# build libtasn1
RUN wget -qO- ${LIBTASN1} | tar xvzf -
RUN cd libtasn1-${TASN_VERION} && ./configure --prefix=/usr && make && make install

# build p11-kit static lib
RUN wget -qO- ${P11} | tar Jxvf -
RUN cd p11-kit-${P11_VERSION} && ./configure --prefix=/usr && make && make install

# build gnutls
RUN wget -qO- ${GNUTLS} | tar Jxvf -
RUN cd gnutls-${GNUTLS_VERSION} && ./configure --prefix=/usr --enable-static --without-p11-kit && make && make install
 
# build aria2
RUN wget -qO- ${ARIA2} | tar xvzf -
RUN cd aria2-${ARIA2_VERSION} && sed -i'' "443s/16/4096/g" src/OptionHandlerFactory.cc &&\
	# dynamic build setting
	# ./configure && make -j 8 &&\
	# static build setting
	./configure ARIA2_STATIC=yes --with-gnutls --without-openssl --with-ca-bundle='/etc/ssl/certs/ca-certificates.crt' && make -j 8 &&\
	mkdir ../../aria2 && cp ./src/aria2c ../../aria2 && strip ../../aria2/aria2c


FROM alpine:3.15 as resolver

ENV VERSION 1.4.1
ENV UI_VERSION 1.2.4
WORKDIR /opt/builder

ENV WEBUI=https://github.com/mayswind/AriaNg/releases/download/${UI_VERSION}/AriaNg-${UI_VERSION}-AllInOne.zip

RUN wget $WEBUI -O ui.zip \
	&& mkdir ../ui \
	&& unzip ui.zip -d ../ui


FROM nginxinc/nginx-unprivileged:1.21-alpine

WORKDIR /opt/aria2
VOLUME [ "/data" ]
EXPOSE 8080

# for dynamic build install deps
# RUN apk add gnutls nettle gmp libstdc++\
# 	libssh2 c-ares expat zlib sqlite-libs
# RUN adduser -S appuser -u 1000 -G root
# USER appuser

COPY --from=resolver /opt/ui /usr/share/nginx/html
COPY --from=builder /opt/aria2/aria2c /usr/sbin
COPY scripts ./scripts
COPY config config
COPY .aria2 .aria2

# RUN mkdir .aria2 && touch .aria2/aria2.session &&\
# 	touch .aria2/dht.dat && touch .aria2/dht6.dat

ENTRYPOINT ["./scripts/start.sh" ]
# secret is MD5('create it never known')
CMD [ "--enable-rpc=true","--conf-path","./config/aria2.conf","--rpc-secret","aadd6df9284fa9becd2eb3b51818c5c2","--rpc-listen-port","8081" ]