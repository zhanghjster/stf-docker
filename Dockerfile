FROM centos
MAINTAINER benx zhanghjster@gmail.com

RUN yum -y install epel-release
RUN yum repolist
RUN yum -y install perl cpan make vim gcc gcc-c++ wget\
  	 mysql-devel  openssl openssl-devel  tcl tcl-devel  libgearman-devel  \
	 memcached openssh-server mysql  \
	 && rm -fr /var/cache/yum/*  \
	 && yum clean all

# 安装perl依赖
RUN wget https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
	 --no-check-certificate -O /usr/local/bin/cpanm &&         \
	chmod +x  /usr/local/bin/cpanm                                
ENV "PERL_CPANM_OPT" "--mirror http://mirrors.163.com/cpan/"
RUN cpanm -f TAP::Harness::Env
RUN cpanm -f Module::Build::Tiny
RUN cpanm -f Redis
RUN cpanm -f Data::Dumper::Concise
RUN cpanm -f Starlet
COPY ./stf/cpanfile /cpanfile
RUN cd / && cpanm -f installdeps .

# 配置ssh
RUN mkdir -p /var/run/sshd
RUN rm -f /etc/ssh/ssh_host* \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' \
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''\
    && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
    && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
RUN mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys

RUN echo '#!/bin/bash' >> /run.sh && echo '/usr/sbin/sshd -D' >> /run.sh
RUN chmod 755 /run.sh

EXPOSE 22 9000

CMD ["/run.sh"]
