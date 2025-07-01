FROM docker.io/library/debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Add Adoptium repository for Java 21
RUN apt-get update -yqq && \
    apt-get install -yqq wget apt-transport-https gnupg && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

RUN apt-get update -yqq && \
    apt-get install -yqq \
                   ansible \
                   apt-utils \
		   cron \
                   git \
                   locales \
                   openssh-server \
                   python3 \
                   python3-debian \
                   python3-psycopg2 \
                   sudo \
                   systemd \
                   temurin-21-jre \
                   whois # mkpasswd provided by whois package

RUN mkdir -p /etc/ansible/facts.d

#####################################################################
## WARNING: THIS ALLOWS FOR COMPLETELY UNAUTHENTICATED SSH SESSIONS #
####### FOR TESTING ENVIRONMENT ONLY! ###############################
RUN echo "root:$(mkpasswd -s </dev/null)" | chpasswd -e
RUN sed -i'' -e's/^#PermitRootLogin prohibit-password$/PermitRootLogin yes/' /etc/ssh/sshd_config \
        && sed -i'' -e's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' /etc/ssh/sshd_config \
        && sed -i'' -e's/^#PermitEmptyPasswords no$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config \
        && sed -i'' -e's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# ✅ NEW: Install Maven inside this image too
RUN apt-get update -yqq && \
    apt-get install -yqq maven