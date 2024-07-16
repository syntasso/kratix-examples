FROM "alpine"

LABEL org.opencontainers.image.authors="kratix@syntasso.io"
LABEL org.opencontainers.image.source=https://github.com/syntasso/kratix-examples

RUN [ "mkdir", "/tmp/transfer" ]
RUN apk update && apk add --no-cache yq curl

RUN mkdir /scripts
ADD reconcile-bucket /scripts/
ADD update-status /scripts/

ENV PATH="/scripts:${PATH}"

CMD [ "reconcile-bucket" ]
ENTRYPOINT []
