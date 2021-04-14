ARG VERSION=0.1.0

FROM registry.access.redhat.com/ubi8/python-38 as BUILD

LABEL summary="Director server used to orchestrate system deployments." \
      description="Director server used to orchestrate system deployments." \
      io.k8s.description="Director server used to orchestrate system deployments." \
      io.k8s.display-name="Director server container" \
      io.openshift.expose-services="5555:job,5556:status,5557:heartbeat" \
      io.openshift.tags="cloudnull,director" \
      name="director" \
      version="${VERSION}" \
      maintainer="cloudnull.io <kevin@cloudnull.com>"

USER root

WORKDIR /build
RUN python3.8 -m venv /build/builder
RUN /build/builder/bin/pip install --force --upgrade pip setuptools bindep wheel
ADD . /build/
RUN bash -c "/build/tools/dev-setup.sh /director python3.8"

FROM registry.access.redhat.com/ubi8/ubi-minimal
EXPOSE 5555
EXPOSE 5556
EXPOSE 5557
COPY --from=BUILD /etc/yum.repos.d /etc/yum.repos.d
RUN microdnf install -y openssh-clients python3.8 zeromq libsodium && rm -rf /var/cache/{dnf,yum}
RUN /bin/python3.8 -m venv --upgrade /director
COPY --from=BUILD /director /director
ADD assets/entrypoint /bin/entrypoint
RUN chmod +x /bin/entrypoint
USER 1001
ENTRYPOINT ["entrypoint"]
