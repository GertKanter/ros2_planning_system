# This dockerfile expects proxies to be set via --build-arg if needed
# It also expects to be contained in the /ros2_planning_system root folder for file copy
#
# Example build command:
# export CMAKE_BUILD_TYPE=Debug
# docker build -t nav2:release_branch \
#   --build-arg FROM_IMAGE=dashing \
#   --build-arg CMAKE_BUILD_TYPE \
#   -f Dockerfile.release_branch ./

ARG FROM_IMAGE=dashing
FROM ros:$FROM_IMAGE

RUN rosdep update

# copy ros package repo
ENV NAV2_WS /opt/nav2_ws
RUN mkdir -p $NAV2_WS/src
WORKDIR $NAV2_WS/src
COPY ./ ros2_planning_system/

# install ros2_planning_system package dependencies
WORKDIR $NAV2_WS
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    apt-get update && \
    rosdep install -q -y \
      --from-paths \
        src \
      --ignore-src \
    && rm -rf /var/lib/apt/lists/*

# build ros2_planning_system package source
ARG CMAKE_BUILD_TYPE=Release
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build \
      --symlink-install \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE

# source ros2_planning_system workspace from entrypoint
RUN sed --in-place --expression \
      '$isource "$NAV2_WS/install/setup.bash"' \
      /ros_entrypoint.sh
