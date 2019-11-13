FROM archlinux:latest

RUN pacman -Syu --noconfirm \
      git \
      devtools \
      sudo \
      base \
      base-devel

RUN useradd -m builder \
  && echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN mkdir /repo && chown builder:builder /repo
USER builder
WORKDIR /home/builder

RUN gpg --recv-keys DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A

RUN cd /tmp \
      && git clone --depth 1 https://aur.archlinux.org/aurutils-git.git \
      && cd aurutils-git \
      && makepkg -si --noconfirm

RUN cd /tmp \
      && git clone --depth 1 https://aur.archlinux.org/python2-crcmod.git \
      && cd python2-crcmod \
      && makepkg -si --noconfirm

RUN cd /tmp \
      && git clone --depth 1 https://aur.archlinux.org/google-cloud-sdk.git \
      && cd google-cloud-sdk \
      && makepkg -si --noconfirm

RUN sudo /bin/bash -c "echo -e '[ahayworth]\nSigLevel = Optional TrustAll\nServer = file:///repo' >> /etc/pacman.conf"
RUN repo-add /repo/ahayworth.db.tar
RUN sudo pacman -Syu
RUN sudo ln -sf /usr/sbin/archbuild /usr/local/bin/aur-x86_64-build
RUN sudo cp /etc/pacman.conf /usr/share/devtools/pacman-aur.conf
