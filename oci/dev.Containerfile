FROM ghcr.io/marmotitude/s3-tester:tools

# git, fish
RUN apt update && apt install -y git fish;

# nvim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz;
RUN tar -C /opt -xzf nvim-linux64.tar.gz; \
    ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim;

# node, npm and yarn
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs

