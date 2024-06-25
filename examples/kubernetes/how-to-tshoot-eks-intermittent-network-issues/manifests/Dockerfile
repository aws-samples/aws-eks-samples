FROM public.ecr.aws/aws-cli/aws-cli

# Install necessary packages
RUN yum update -y \
    && yum install -y \
    lsof \
    tcpdump \
    libcap \
    && yum clean all

# Create a non-root user
RUN useradd -m -s /bin/bash tcpdump_user

# Add the non-root user to the tcpdump group and grant necessary capabilities
RUN usermod -a -G tcpdump tcpdump_user \
    && setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# Switch to the non-root user
USER tcpdump_user

# Set the working directory
WORKDIR /home/tcpdump_user

ENTRYPOINT ["/bin/sh"]
