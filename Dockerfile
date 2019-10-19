FROM alpine:3.9 as builder

LABEL MAINTAINER='dogbutcat@hotmail.com'

ENV ARIA2_VERSION 1.35.0
ENV ARIA2=https://github.com/aria2/aria2/releases/download/release-${ARIA2_VERSION}/aria2-${ARIA2_VERSION}.tar.gz
WORKDIR /opt/builder

# dynamic build setting
# RUN apk add gnutls-dev nettle-dev gmp-dev g++ make \
# 	libssh2-dev c-ares-dev expat-dev zlib-dev sqlite-dev pkgconfig

# static build setting
RUN apk add openssl-dev nettle-dev gmp-dev g++ make binutils\
	libssh2-dev c-ares-dev expat-dev zlib-dev sqlite-dev sqlite-static pkgconfig

RUN wget -qO- ${ARIA2} | tar xvzf -

RUN cd aria2-${ARIA2_VERSION} && sed -i'' "443s/16/4096/g" src/OptionHandlerFactory.cc &&\
	# dynamic build setting
	# ./configure && make -j 8 &&\
	# static build setting
	./configure ARIA2_STATIC=yes --without-gnutls --with-openssl && make -j 8 &&\
	mkdir ../../aria2 && cp ./src/aria2c ../../aria2 && strip ../../aria2/aria2c


FROM alpine:3.9 as resolver

ENV VERSION 1.1
ENV UI_VERSION 1.1.4
WORKDIR /opt/builder

ENV WEBUI=https://github.com/mayswind/AriaNg/releases/download/${UI_VERSION}/AriaNg-${UI_VERSION}-AllInOne.zip

RUN wget $WEBUI -O ui.zip \
	&& mkdir ../ui \
	&& unzip ui.zip -d ../ui


FROM nginx:1.15.10-alpine

WORKDIR /opt/aria2
VOLUME [ "/data" ]
EXPOSE 80

# for dynamic build install deps
# RUN apk add gnutls nettle gmp libstdc++\
# 	libssh2 c-ares expat zlib sqlite-libs

COPY --from=resolver /opt/ui /usr/share/nginx/html
COPY --from=builder /opt/aria2/aria2c /usr/sbin
COPY scripts ./scripts
COPY config config
COPY .aria2 .aria2

# RUN mkdir .aria2 && touch .aria2/aria2.session &&\
# 	touch .aria2/dht.dat && touch .aria2/dht6.dat

ENTRYPOINT ["./scripts/start.sh" ]
# secret is MD5('create it never known')
CMD [ "--enable-rpc=true","--conf-path","./config/aria2.conf","--rpc-secret","aadd6df9284fa9becd2eb3b51818c5c2","--rpc-listen-port","8080" ]