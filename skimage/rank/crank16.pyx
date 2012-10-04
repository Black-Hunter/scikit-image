""" to compile this use:
>>> python setup.py build_ext --inplace

to generate html report use:
>>> cython -a crank16.pxd

"""

#cython: cdivision=True
#cython: boundscheck=False
#cython: nonecheck=False
#cython: wraparound=False

import numpy as np
cimport numpy as np

# import main loop
from core16 cimport rank16

# -----------------------------------------------------------------
# kernels uint16 take extra parameter for defining the bitdepth
# -----------------------------------------------------------------

cdef inline np.uint16_t kernel_autolevel(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i,imin,imax,delta

    if pop:
        for i in range(maxbin-1,-1,-1):
            if histo[i]:
                imax = i
                break
        for i in range(maxbin):
            if histo[i]:
                imin = i
                break
    delta = imax-imin
    if delta>0:
        return <np.uint16_t>(maxbin*1.*(g-imin)/delta)
    else:
        return <np.uint16_t>(imax-imin)

cdef inline np.uint16_t kernel_bottomhat(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i

    for i in range(maxbin):
        if histo[i]:
            break

    return <np.uint16_t>(g-i)


cdef inline np.uint16_t kernel_egalise(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i
    cdef float sum = 0.

    if pop:
        for i in range(maxbin):
            sum += histo[i]
            if i>=g:
                break

        return <np.uint16_t>((maxbin*1.*sum)/pop)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_gradient(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i,imin,imax

    if pop:
        for i in range(maxbin-1,-1,-1):
            if histo[i]:
                imax = i
                break
        for i in range(maxbin):
            if histo[i]:
                imin = i
                break
        return <np.uint16_t>(imax-imin)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_maximum(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i

    if pop:
        for i in range(maxbin-1,-1,-1):
            if histo[i]:
                return <np.uint16_t>(i)

    return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_mean(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i
    cdef float mean = 0.

    if pop:
        for i in range(maxbin):
            mean += histo[i]*i
        return <np.uint16_t>(mean/pop)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_meansubstraction(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i
    cdef float mean = 0.

    if pop:
        for i in range(maxbin):
            mean += histo[i]*i
        return <np.uint16_t>((g-mean/pop)/2.+midbin)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_median(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i
    cdef float sum = pop/2.0

    if pop:
        for i in range(maxbin):
            if histo[i]:
                sum -= histo[i]
                if sum<0:
                    return <np.uint16_t>(i)

    return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_minimum(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i

    if pop:
        for i in range(maxbin):
            if histo[i]:
                return <np.uint16_t>(i)

    return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_modal(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int hmax=0,imax=0

    if pop:
        for i in range(maxbin):
            if histo[i]>hmax:
                hmax = histo[i]
                imax = i
        return <np.uint16_t>(imax)

    return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_morph_contr_enh(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i,imin,imax

    if pop:
        for i in range(maxbin-1,-1,-1):
            if histo[i]:
                imax = i
                break
        for i in range(maxbin):
            if histo[i]:
                imin = i
                break
        if imax-g < g-imin:
            return <np.uint16_t>(imax)
        else:
            return <np.uint16_t>(imin)
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_pop(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    return <np.uint16_t>(pop)

cdef inline np.uint16_t kernel_threshold(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i
    cdef float mean = 0.

    if pop:
        for i in range(maxbin):
            mean += histo[i]*i
        return <np.uint16_t>(g>(mean/pop))
    else:
        return <np.uint16_t>(0)

cdef inline np.uint16_t kernel_tophat(int* histo, float pop, np.uint16_t g,int bitdepth,int maxbin, int midbin):
    cdef int i

    for i in range(maxbin-1,-1,-1):
        if histo[i]:
            break

    return <np.uint16_t>(i-g)

# -----------------------------------------------------------------
# python wrappers
# -----------------------------------------------------------------
def autolevel(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """bottom hat
    """
    return rank16(kernel_autolevel,image,selem,mask,out,shift_x,shift_y,bitdepth)

def bottomhat(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """bottom hat
    """
    return rank16(kernel_bottomhat,image,selem,mask,out,shift_x,shift_y,bitdepth)

def egalise(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local egalisation of the gray level
    """
    return rank16(kernel_egalise,image,selem,mask,out,shift_x,shift_y,bitdepth)

def gradient(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local maximum - local minimum gray level
    """
    return rank16(kernel_gradient,image,selem,mask,out,shift_x,shift_y,bitdepth)

def maximum(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local maximum gray level
    """
    return rank16(kernel_maximum,image,selem,mask,out,shift_x,shift_y,bitdepth)

def mean(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """average gray level (clipped on uint8)
    """
    return rank16(kernel_mean,image,selem,mask,out,shift_x,shift_y,bitdepth)

def meansubstraction(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """(g - average gray level)/2+midbin (clipped on uint8)
    """
    return rank16(kernel_meansubstraction,image,selem,mask,out,shift_x,shift_y,bitdepth)

def median(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local median
    """
    return rank16(kernel_median,image,selem,mask,out,shift_x,shift_y,bitdepth)

def minimum(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local minimum gray level
    """
    return rank16(kernel_minimum,image,selem,mask,out,shift_x,shift_y,bitdepth)

def morph_contr_enh(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """morphological contrast enhancement
    """
    return rank16(kernel_morph_contr_enh,image,selem,mask,out,shift_x,shift_y,bitdepth)

def modal(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """local mode
    """
    return rank16(kernel_modal,image,selem,mask,out,shift_x,shift_y,bitdepth)

def pop(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """returns the number of actual pixels of the structuring element inside the mask
    """
    return rank16(kernel_pop,image,selem,mask,out,shift_x,shift_y,bitdepth)

def threshold(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """returns maxbin-1 if gray level higher than local mean, 0 else
    """
    return rank16(kernel_threshold,image,selem,mask,out,shift_x,shift_y,bitdepth)

def tophat(np.ndarray[np.uint16_t, ndim=2] image,
            np.ndarray[np.uint8_t, ndim=2] selem,
            np.ndarray[np.uint8_t, ndim=2] mask=None,
            np.ndarray[np.uint16_t, ndim=2] out=None,
            char shift_x=0, char shift_y=0, int bitdepth=8):
    """top hat
    """
    return rank16(kernel_tophat,image,selem,mask,out,shift_x,shift_y,bitdepth)
