FROM iamlow/ros:humble-desktop

ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -y \
  && apt-get install --no-install-recommends -y \
    ros-humble-desktop \
    ros-humble-rmw-cyclonedds-cpp \
    python3-pip \
  && pip install -U paho-mqtt pydantic \
  && apt-get purge -y python3-pip \
  && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN /bin/bash -c /ros_entrypoint.sh
RUN mkdir -p /root/ros2_ws/src \
  && cd /root/ros2_ws && colcon build --symlink-install

COPY mbdds_interfaces /root/ros2_ws/src

RUN cd /root/ros2_ws \
  && /ros_entrypoint.sh colcon build --packages-select mbdds_interfaces \
  && colcon build --packages-select mbdds \
  && chmod +x /root/ros2_ws/install/setup.bash \
  && /bin/bash -c /root/ros2_ws/install/setup.bash

COPY <<EOF /mbdds_entrypoint.sh
#!/bin/bash
set -e

# setup ros2 environment
source "/root/ros2_ws/install/setup.bash"
source "/ros_entrypoint.sh"
EOF

RUN chmod +x /mbdds_entrypoint.sh

ENTRYPOINT ["/mbdds_entrypoint.sh"]
# CMD ["ros2", "run", "mbdds", "tsteleop"]
