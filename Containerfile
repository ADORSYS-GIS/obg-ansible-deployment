FROM docker.io/library/debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -yqq && \
    apt-get install -yqq \
                   ansible \
		   cron \
                   git \
                   locales \
                   openssh-server \
                   python3 \
                   python3-debian \
                   python3-psycopg2 \
                   systemd \
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
