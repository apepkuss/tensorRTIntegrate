ECHO = @echo
OUTNAME = trtrun
CC := g++
CUCC := nvcc
SRCDIR := src
OBJDIR := objs
# LEAN := /datav/newbb/lean
#BINDIR := $(LEAN)/tensorRTIntegrate
BINDIR := workspace

TENSORRT_NAME := TensorRT-7.0.0.11
#TENSORRT_NAME := TensorRT-6.0.1.8-cuda10.2-cudnn7.6
CFLAGS := -std=c++11 -fPIC -g -O3 -fopenmp -w -DONNX_ML -DNDEBUG 
CUFLAGS := -std=c++11 -m64 -Xcompiler -fPIC -g -O3 -w -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_53,code=sm_53
INC_OPENCV := /usr/include/opencv4/
INC_LOCAL := ./src ./src/builder ./src/common ./src/infer ./src/plugin ./src/plugin/plugins
INC_SYS := /usr/local/include/ /usr/src/linux-headers-4.9.140-tegra-ubuntu18.04_aarch64/kernel-4.9/arch/arm64/include/
INC_CUDA := /usr/local/cuda-10.0/include /usr/include/aarch64-linux-gnu/
INCS := $(INC_SYS) $(INC_OPENCV) $(INC_LOCAL) $(INC_CUDA)
INCS := $(foreach inc, $(INCS), -I$(inc))

LIB_CUDA := /usr/local/cuda-10.0/lib64 /usr/lib/python3.6/dist-packages/tensorrt /usr/include/aarch64-linux-gnu/ /usr/lib/aarch64-linux-gnu/tegra
LIB_SYS := /usr/local/lib
LIB_OPENCV := /usr/lib/aarch64-linux-gnu/ 
LIBS := $(LIB_SYS) $(LIB_CUDA) $(LIB_OPENCV)
LIBS := $(foreach lib, $(LIBS),-L$(lib))

RPATH := $(LIB_SYS) $(LIB_CUDA) $(LIB_OPENCV)
RPATH := $(foreach lib, $(RPATH),-Wl,-rpath=$(lib))

LD_OPENCV := opencv_core opencv_highgui opencv_imgproc opencv_video opencv_videoio opencv_imgcodecs
LD_NVINFER := nvinfer nvinfer_plugin nvparsers
LD_CUDA := cuda curand cublas cudart cudnn
LD_SYS := stdc++
LDS := $(LD_SYS) $(LD_OPENCV) $(LD_NVINFER) $(LD_CUDA)
LDS := $(foreach lib, $(LDS), -l$(lib))

SRCS := $(shell cd $(SRCDIR) && find -name "*.cpp")
OBJS := $(patsubst %.cpp,%.o,$(SRCS))
OBJS := $(foreach item,$(OBJS),$(OBJDIR)/$(item))
CUS := $(shell cd $(SRCDIR) && find -name "*.cu")
CUOBJS := $(patsubst %.cu,%.o,$(CUS))
CUOBJS := $(foreach item,$(CUOBJS),$(OBJDIR)/$(item))
OBJS := $(subst /./,/,$(OBJS))
CUOBJS := $(subst /./,/,$(CUOBJS))

all: $(BINDIR)/$(OUTNAME)
	$(ECHO) Done, now you can run this program with \"make run\" command.

run: all
	@cd $(BINDIR) && ./$(OUTNAME)

$(BINDIR)/$(OUTNAME): $(OBJS) $(CUOBJS)
	$(ECHO) Linking: $@
	@g++  $(LIBS) -o $@ $^ $(LDS) $(RPATH) -pthread -lprotobuf 

$(CUOBJS) : $(OBJDIR)/%.o : $(SRCDIR)/%.cu
	@if [ ! -d $@ ]; then mkdir -p $(dir $@); fi
	$(ECHO) Compiling: $<
	@$(CUCC) $(CUFLAGS) $(INCS) -c -o $@ $<

$(OBJS) : $(OBJDIR)/%.o : $(SRCDIR)/%.cpp
	@if [ ! -d $@ ]; then mkdir -p $(dir $@); fi
	$(ECHO) Compiling: $<
	@$(CC) $(CFLAGS) $(INCS) -c -o $@ $<

clean:
	rm -rf $(OBJDIR) $(BINDIR)/$(OUTNAME)
