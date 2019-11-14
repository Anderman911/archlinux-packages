FROM archlinux:latest

RUN pacman -Syu --noconfirm \
      git \
      devtools \
      sudo \
      base \
      base-devel \
      python-pip

RUN useradd -m builder \
  && echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN mkdir /repo && chown builder:builder /repo

RUN pip install b2==1.4.2

USER builder
WORKDIR /home/builder
RUN gpg --recv-keys DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A

RUN cd /tmp \
      && git clone --depth 1 https://aur.archlinux.org/aurutils-git.git \
      && cd aurutils-git \
      && makepkg -si --noconfirm

COPY pacman.conf.repo /tmp
RUN cat /etc/pacman.conf /tmp/pacman.conf.repo > /tmp/pacman.conf
RUN sudo mv /tmp/pacman.conf /etc/pacman.conf
RUN repo-add /repo/ahayworth.db.tar
RUN sudo pacman -Syu --noconfirm

RUN sudo ln -sf /usr/sbin/archbuild /usr/local/bin/aur-x86_64-build
RUN sudo cp /etc/pacman.conf /usr/share/devtools/pacman-aur.conf
