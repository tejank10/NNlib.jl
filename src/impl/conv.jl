function psize(p, x)
  nd = ndims(x)-2
  if isa(p,Number)
    fill(Int(p),nd)
  elseif length(p)==nd
    collect(Int,p)
  else
    throw(DimensionMismatch("psize: $p $nd"))
  end
end

function im2col_2d!{T}(img::AbstractArray{T,3}, col::AbstractArray{T,2}, width::Int, height::Int, channels::Int,
  kernel_w::Int, kernel_h::Int, pad_w::Int, pad_h::Int, stride_w::Int, stride_h::Int,
  dil_w::Int, dil_h::Int, mode::Int)

  height_col = div(height + 2pad_h - (kernel_h - 1) * dil_h - 1, stride_h) + 1
  width_col = div(width + 2pad_w - (kernel_w - 1) * dil_w - 1, stride_w) + 1
  channels_col = channels * kernel_h * kernel_w

  #pragma omp parallel for
  for c = 1:channels_col
    w_offset = (c - 1) % kernel_w
    h_offset = div(c - 1, kernel_w) % kernel_h
    c_im = div(c - 1, kernel_h * kernel_w)
    if mode == 0
      w_offset = kernel_w - 1 - w_offset
      h_offset = kernel_h - 1 - h_offset
    end
    for h = 1:height_col
      for w = 1:width_col
        h_pad = (h - 1) * stride_h - pad_h + h_offset * dil_h
        w_pad = (w - 1) * stride_w - pad_w + w_offset * dil_w
        if h_pad >= 0 && h_pad < height && w_pad >= 0 && w_pad < width
          col[((c - 1)*height_col+h-1) * width_col + w] =
           img[(c_im  * height + h_pad) * width + w_pad + 1]
        else
          col[((c - 1)*height_col+h - 1) * width_col + w] = 0
        end
      end
    end
  end
end

function col2im_2d!{T}(col::AbstractArray{T,2}, img::AbstractArray{T,3}, width::Int, height::Int,
  channels::Int, kernel_w::Int, kernel_h::Int, pad_w::Int, pad_h::Int, stride_w::Int,
  stride_h::Int, dil_h::Int, dil_w::Int, mode::Int)

  height_col = div(height + 2pad_h - (kernel_h - 1) * dil_h - 1, stride_h) + 1
  width_col = div(width + 2pad_w - (kernel_w - 1) * dil_w - 1, stride_w) + 1
  channels_col = channels * kernel_h * kernel_w

  fill!(img, 0)
  #pragma omp parallel for
  for c = 1:channels_col
    w_offset = (c - 1) % kernel_w
    h_offset = div(c - 1,  kernel_w) % kernel_h
    c_im = div(c - 1, kernel_h * kernel_w)
    if mode == 0
      w_offset = kernel_w - 1 - w_offset
      h_offset = kernel_h - 1 - h_offset
    end
    for h = 1:height_col, w = 1:width_col
      h_pad = (h - 1) * stride_h - pad_h + h_offset * dil_h
      w_pad = (w - 1) * stride_w - pad_w + w_offset * dil_w
      if h_pad >= 0 && h_pad < height && w_pad >= 0 && w_pad < width
        cval::T = col[((c - 1) * height_col + h - 1) * width_col + w]
        img[(c_im * height + h_pad) * width + w_pad + 1] += cval
      end
    end
  end
end

function im2col_3d!{T}(img::AbstractArray{T,4}, col::AbstractArray{T,2}, width::Int, height::Int, depth::Int,
  channels::Int, kernel_w::Int, kernel_h::Int, kernel_d::Int, pad_w::Int, pad_h::Int, pad_d::Int,
  stride_w::Int, stride_h::Int, stride_d::Int, dil_w::Int, dil_h::Int, dil_d::Int, mode::Int)

  height_col = div(height + 2pad_h - (kernel_h - 1) * dil_h - 1, stride_h) + 1
  width_col = div(width + 2pad_w - (kernel_w - 1) * dil_w - 1, stride_w) + 1
  depth_col = div(depth + 2pad_d - (kernel_d - 1) * dil_d - 1, stride_d) + 1
  channels_col = channels * kernel_h * kernel_w * kernel_d


  #pragma omp parallel for
  for c = 1:channels_col
    w_offset = (c - 1) % kernel_w
    h_offset = div(c - 1, kernel_w) % kernel_h
    d_offset = div(c - 1, kernel_w * kernel_h) % kernel_d
    c_im = div(c - 1, kernel_w * kernel_h * kernel_d)
    if mode == 0
      w_offset = kernel_w - 1 - w_offset
      h_offset = kernel_h - 1 - h_offset
      d_offset = kernel_d - 1 - d_offset
    end
    for d = 1:depth_col, h = 1:height_col, w = 1:width_col
      d_pad = (d - 1) * stride_d - pad_d + d_offset * dil_d
      h_pad = (h - 1) * stride_h - pad_h + h_offset * dil_h
      w_pad = (w - 1) * stride_w - pad_w + w_offset * dil_w

      if d_pad >= 0 && d_pad < depth && h_pad >= 0 && h_pad < height &&
        w_pad >= 0 && w_pad < width
        col[(((c - 1) * depth_col + d - 1) * height_col + h - 1) * width_col + w] =
    	    img[((c_im * depth + d_pad) * height + h_pad) * width + w_pad + 1]
    	else
    	  col[(((c - 1) * depth_col + d - 1) * height_col + h - 1) * width_col + w] = 0
      end
    end
  end
end

function col2im_3d!{T}(col::AbstractArray{T,2}, img::AbstractArray{T,4}, width::Int, height::Int,
  depth::Int, channels::Int, kernel_w::Int, kernel_h::Int, kernel_d::Int,
  pad_w::Int, pad_h::Int, pad_d::Int, stride_w::Int, stride_h::Int, stride_d::Int,
  dil_w::Int, dil_h::Int, dil_d::Int, mode::Int)

  height_col = div(height + 2pad_h - (kernel_h - 1) * dil_h - 1, stride_h) + 1
  width_col = div(width + 2pad_w - (kernel_w - 1) * dil_w - 1, stride_w) + 1
  depth_col = div(depth + 2pad_d - (kernel_d - 1) * dil_d - 1, stride_d) + 1
  channels_col = channels * kernel_h * kernel_w * kernel_d

  fill!(img, 0)
  #pragma omp parallel for
  for c = 1:channels_col
    w_offset = (c - 1) % kernel_w;
    h_offset = div(c - 1, kernel_w) % kernel_h
    d_offset = div(c - 1, kernel_w * kernel_h) % kernel_d
    c_im = div(c - 1, kernel_h * kernel_w * kernel_d)

    if mode == 0
      w_offset = kernel_w - 1 - w_offset
      h_offset = kernel_h - 1 - h_offset
      d_offset = kernel_d - 1 - d_offset
    end

    for d = 1:depth_col, h = 1:height_col, w = 1:width_col
      d_pad = (d - 1) * stride_d - pad_d + d_offset * dil_d
    	h_pad = (h - 1) * stride_h - pad_h + h_offset * dil_h
    	w_pad = (w - 1) * stride_w - pad_w + w_offset * dil_w
    	if h_pad >= 0 && h_pad < height && w_pad >= 0 && w_pad < width &&
        d_pad >= 0 && d_pad < depth
    	  cval::T = col[(((c - 1) * depth_col + d - 1) * height_col + h - 1) * width_col + w]
    	  iidx = ((c_im * depth + d_pad) * height + h_pad) * width + w_pad + 1
              #pragma omp atomic
    	  img[iidx] += cval
    	end
    end
  end
end

function im2col_nd!{T}(img::AbstractArray, col::AbstractArray{T,2},
  kernel_dim::NTuple, pad::AbstractArray, stride::AbstractArray, mode::Int)

  img_dim = size(img)
  n_dim = ndims(img) - 1

  dim_col = zeros(Int, n_dim+1)
  kernel_dim_prod = dim_col[1:n_dim]
  dim_col_prod = kernel_dim_prod[:]
  offset = dim_col[:]
  dim_iter = kernel_dim_prod[:]
  dim_pad = kernel_dim_prod[:]

  i::Int = 1

  dim_col[1] = div(img_dim[1] + 2pad[1] - kernel_dim[1], stride[1]) + 1
  dim_col_prod[1] = dim_col[1]
  kernel_dim_prod[1] = kernel_dim[1]

  while (i += 1) <= n_dim
    dim_col[i] = div(img_dim[i] + 2pad[i] - kernel_dim[i], stride[i]) + 1
    dim_col_prod[i] = dim_col_prod[i-1] * dim_col[i]
    kernel_dim_prod[i] = kernel_dim_prod[i-1] * kernel_dim[i]
  end

  dim_col[end] = img_dim[end] * kernel_dim_prod[end]
  c::Int = 0
  while (c += 1) <= dim_col[end]
    offset[1] = (c - 1) % kernel_dim[1]

    i = 1
    while (i += 1) <= n_dim
      offset[i] = div(c - 1, kernel_dim_prod[i-1]) % kernel_dim[i]
    end
    offset[end] = div(c - 1, kernel_dim_prod[end])
    if mode == 0
      i = 0
      while (i += 1) <= n_dim
        offset[i] = kernel_dim[i] - offset[i] - 1
      end
    end

    i = 0
    while (i += 1) <= dim_col_prod[end]
      dim_iter[1] = (i - 1) % dim_col[1]

      dim_pad[1] = dim_iter[1] * stride[1] - pad[1] + offset[1]
      dim_pad_checker::Int = (0 <= dim_pad[1] < img_dim[1])
      col_ind::Int = c - 1

      j::Int = n_dim + 1
      while (j -= 1) > 1
        dim_iter[j] = div(i - 1, dim_col_prod[j-1]) % dim_col[j]
        dim_pad[j] = dim_iter[j] * stride[j] - pad[j] + offset[j]
        col_ind = col_ind * dim_col[j] + dim_iter[j]
        dim_pad_checker += (0 <= dim_pad[j] < img_dim[j])
      end
      col_ind = col_ind * dim_col[1] + dim_iter[1]
      img_ind::Int = offset[end]

      if dim_pad_checker == n_dim
        j = n_dim + 1
        while (j -= 1) > 0
          img_ind = img_ind * img_dim[j] + dim_pad[j]
        end
        col[col_ind + 1] = img[img_ind + 1]
      else
        col[col_ind + 1] = 0
      end
    end
  end
end

function col2im_nd!{T}(col::AbstractArray{T,2}, img::AbstractArray{T},
  kernel_dim::NTuple, pad::AbstractArray{Int},
  stride::AbstractArray{Int}, mode::Int)

  img_dim = size(img)
  n_dim = ndims(img) - 1

  dim_col = zeros(Int, n_dim+1)
  kernel_dim_prod = dim_col[1:n_dim]
  dim_col_prod = kernel_dim_prod[:]
  offset = dim_col[:]
  dim_iter = kernel_dim_prod[:]
  dim_pad = kernel_dim_prod[:]

  dim_col[1] = div(img_dim[1] + 2pad[1] - kernel_dim[1], stride[1]) + 1
  dim_col_prod[1] = dim_col[1]
  kernel_dim_prod[1] = kernel_dim[1]

  fill!(img, 0)

  i::Int = 1

  while (i += 1) <= n_dim
    dim_col[i] = div(img_dim[i] + 2pad[i] - kernel_dim[i], stride[i]) + 1
    dim_col_prod[i] = dim_col_prod[i-1] * dim_col[i]
    kernel_dim_prod[i] = kernel_dim_prod[i-1] * kernel_dim[i]
  end

  dim_col[end] = img_dim[end] * kernel_dim_prod[end]
  c::Int = 0
  while (c += 1) <= dim_col[end]
    offset[1] = (c - 1) % kernel_dim[1]

    i = 1
    while (i += 1) <= n_dim
      offset[i] = div(c - 1, kernel_dim_prod[i-1]) % kernel_dim[i]
    end
    offset[end] = div(c - 1, kernel_dim_prod[end])
    if mode == 0
      i = 0
      while (i += 1) <= n_dim
        offset[i] = kernel_dim[i] - offset[i] - 1
      end
    end

    i = 0
    while (i += 1) <= dim_col_prod[end]
      dim_iter[1] = (i - 1) % dim_col[1]

      dim_pad[1] = dim_iter[1] * stride[1] - pad[1] + offset[1]
      dim_pad_checker::Int = (0 <= dim_pad[1] < img_dim[1])
      col_ind::Int = c - 1

      j::Int = n_dim + 1
      while (j -= 1) > 1
        dim_iter[j] = div(i - 1, dim_col_prod[j-1]) % dim_col[j]
        dim_pad[j] = dim_iter[j] * stride[j] - pad[j] + offset[j]
        col_ind = col_ind * dim_col[j] + dim_iter[j]
        dim_pad_checker += (0 <= dim_pad[j] < img_dim[j])
      end
      col_ind = col_ind * dim_col[1] + dim_iter[1]
      img_ind::Int = offset[end]

      if dim_pad_checker == n_dim
        j = n_dim + 1
        while (j -= 1) > 0
          img_ind = img_ind * img_dim[j] + dim_pad[j]
        end
        img[img_ind + 1] += col[col_ind + 1]
      end
    end
  end
end

function dilation_dims(w, dilation = 1)
  N = ndims(w)
  dims_w = size(w)
  dil = psize(dilation, w)
  ntuple(N) do i
    if i < N - 1
      (dims_w[i] - 1) * dil[i] + 1
    else
      dims_w[i]
    end
  end
end

function im2col_dims(w,y,dilation=1)
    N = ndims(y)
    dil = dilation_dims(w, dilation)
    r,c = 1,1
    for i=1:N-2
        r *= size(y,i)
        c *= dil[i]
    end
    c *= dil[N-1]
    return (r, c)
end

function conv2d!{T}(y::AbstractArray{T,4}, x::AbstractArray{T,4}, w::AbstractArray{T,4};
                  padding=0, stride=1, dilation=1, mode=0, alpha=T(1))
    if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    Wx,Hx,Cx,Nx = size(x)
    Ww,Hw,C1,C2 = dilation_dims(w, dilation)
    if Cx!=C1; throw(DimensionMismatch()); end
    Wy,Hy,Cy,Ny = size(y)
    x2dims = im2col_dims(w,y,dilation)
    x2 = similar(x, x2dims)
    (p1,p2) = psize(padding,x)
    (s1,s2) = psize(stride,x)
    (d1,d2) = psize(dilation, x)
    M,N,K,Y = Wy*Hy,Cy,Ww*Hw*Cx,Wy*Hy*Cy
    yidx = 1
    @inbounds for n in 1:Nx
        im2col2d!(w, x, x2, n, p1, p2, s1, s2, d1, d2, mode)
        gemm!('N','N',M,N,K,alpha,pointer(x2),pointer(w),T(0),pointer(y,yidx))
        yidx += Y
    end
    return y
end

function conv2d_grad_w!{T}(dw::AbstractArray{T,4}, x::AbstractArray{T,4}, w::AbstractArray{T,4}, dy::AbstractArray{T,4};
                   padding=0, stride=1, dilation=1, mode=0, alpha=1)
    # dw = x'*dy
    Wx,Hx,Cx,Nx = size(x)
    Ww,Hw,C1,C2 = dilation_dims(w, dilation)
    Wy,Hy,Cy,Ny = size(dy)
    # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    # @assert Cx==C1 && Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,dy,dilation)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = Wy*Hy*Cy,Ww*Hw*Cx,Cy,Wy*Hy
    alpha,beta = T(alpha),T(1)
    (p1,p2) = psize(padding,x)
    (s1,s2) = psize(stride,x)
    (d1,d2) = psize(dilation,x)
    dyi = 1
    @inbounds for n in 1:Nx
        im2col2d!(w, x, x2, n, p1, p2, s1, s2, d1, d2, mode)
        gemm!('T','N',M,N,K,alpha,pointer(x2),pointer(dy,dyi),beta,pointer(dw))
        dyi += Y
    end
    return dw
end

function conv2d_grad_x!{T}(dx::AbstractArray{T,4}, x::AbstractArray{T,4}, w::AbstractArray{T,4}, dy::AbstractArray{T,4};
                   padding=0, stride=1, dilation=1, mode=0, alpha=1)
    # dx = dy*w'
    Wx,Hx,Cx,Nx = size(x)
    Ww,Hw,C1,C2 = dilation_dims(w, dilation)
    Wy,Hy,Cy,Ny = size(dy)
    # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    @assert Cx==C1 && Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,dy,dilation)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = Wy*Hy*Cy,Wy*Hy,Ww*Hw*Cx,Cy
    alpha,beta = T(alpha),T(0)
    (p1,p2) = psize(padding,x)
    (s1,s2) = psize(stride,x)
    (d1,d2) = psize(dilation,x)
    dyi = 1
    @inbounds for n in 1:Nx
        gemm!('N','T',M,N,K,alpha,pointer(dy,dyi),pointer(w),beta,pointer(x2))
        col2im2d!(w,dx,x2,n,p1,p2,s1,s2,d1,d2,mode)
        dyi += Y
    end
    return dx
end

function im2col2d!(w::AbstractArray{T,4}, x::AbstractArray{T,4}, x2::AbstractArray{T,2},
                 n::Int, p1::Int, p2::Int, s1::Int, s2::Int, d1::Int, d2::Int, mode::Int) where T
    Wx,Hx,Cx,Nx = size(x)
    Ww,Hw,C1,C2 = size(w)
    xn = x[:, :, :, n]
    im2col_2d!(xn,x2,Wx,Hx,Cx,Ww,Hw,p1,p2,s1,s2,d1,d2,mode)
    return x2
end

function col2im2d!(w::AbstractArray{T,4}, x::AbstractArray{T,4}, x2::AbstractArray{T,2},
                 n::Int, p1::Int, p2::Int, s1::Int, s2::Int, d1::Int, d2::Int, mode::Int) where T
    Wx,Hx,Cx,Nx = size(x)
    Ww,Hw,C1,C2 = size(w)
    xn = x[:, :, :, n]
    col2im_2d!(x2,xn,Wx,Hx,Cx,Ww,Hw,p1,p2,s1,s2,d1,d2,mode)
    x[:, :, :, n] = xn
    return x
end

function conv3d!{T}(y::AbstractArray{T,5}, x::AbstractArray{T,5}, w::AbstractArray{T,5};
                  padding=0, stride=1, dilation = 1, mode=0, alpha=T(1))
    if mode != 0 && mode != 1; throw(ArgumentError("conv3d only supports mode=0 or 1.")); end
    Wx,Hx,Dx,Cx,Nx = size(x)
    Ww,Hw,Dw,C1,C2 = dilation_dims(w, dilation)
    if Cx!=C1; throw(DimensionMismatch()); end
    Wy,Hy,Dy,Cy,Ny = size(y)
    # @assert Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,y,dilation)
    x2 = similar(x, x2dims)
    (p1,p2,p3) = psize(padding,x)
    (s1,s2,s3) = psize(stride,x)
    (d1,d2,d3) = psize(dilation,x)
    M,N,K,Y = Wy*Hy*Dy,Cy,Ww*Hw*Dw*Cx,Wy*Hy*Dy*Cy
    yidx = 1
    W = reshape(w, (size(w, 1),:,C1,C2))
    @inbounds for n in 1:Nx
        im2col3d!(w, x, x2, n, p1, p2, p3, s1, s2, s3, d1, d2, d3, mode)
        gemm!('N','N',M,N,K,alpha,pointer(x2),pointer(W),T(0),pointer(y,yidx))
        yidx += Y
    end
    return y
end

function conv3d_grad_w!{T}(dw::AbstractArray{T,5}, x::AbstractArray{T,5}, w::AbstractArray{T,5}, dy::AbstractArray{T,5};
                   padding=0, stride=1, dilation = 1, mode=0, alpha=1)
    # dw = x'*dy
    Wx,Hx,Dx,Cx,Nx = size(x)
    Ww,Hw,Dw,C1,C2 = dilation_dims(w, dilation)
    Wy,Hy,Dy,Cy,Ny = size(dy)
    # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    # @assert Cx==C1 && Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,dy,dilation)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = Wy*Hy*Dy*Cy,Ww*Hw*Dw*Cx,Cy,Wy*Hy*Dy
    alpha,beta = T(alpha),T(1)
    (p1,p2,p3) = psize(padding,x)
    (s1,s2,s3) = psize(stride,x)
    (d1,d2,d3) = psize(dilation,x)
    dyi = 1
    @inbounds for n in 1:Nx
        im2col3d!(w, x, x2, n, p1, p2, p3, s1, s2, s3, d1, d2, d3, mode)
        gemm!('T','N',M,N,K,alpha,pointer(x2),pointer(dy,dyi),beta,pointer(dw))
        dyi += Y
    end
    return dw
end

function conv3d_grad_x!{T}(dx::AbstractArray{T,5}, x::AbstractArray{T,5}, w::AbstractArray{T,5}, dy::AbstractArray{T,5};
                   padding=0, stride=1, dilation = 1, mode=0, alpha=1)
    # dx = dy*w'
    Wx,Hx,Dx,Cx,Nx = size(x)
    Ww,Hw,Dw,C1,C2 = dilation_dims(w, dilation)
    Wy,Hy,Dy,Cy,Ny = size(dy)
    # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    @assert Cx==C1 && Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,dy,dilation)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = Wy*Hy*Dy*Cy,Wy*Hy*Dy,Ww*Hw*Dw*Cx,Cy
    alpha,beta = T(alpha),T(0)
    (p1,p2,p3) = psize(padding,x)
    (s1,s2,s3) = psize(stride,x)
    (d1,d2,d3) = psize(dilation,x)
    dyi = 1
    @inbounds for n in 1:Nx
        gemm!('N','T',M,N,K,alpha,pointer(dy,dyi),pointer(w),beta,pointer(x2))
        col2im3d!(w,dx,x2,n,p1,p2,p3,s1,s2,s3,d1,d2,d3,mode)
        dyi += Y
    end
    return dx
end

function im2col3d!(w::AbstractArray{T,5}, x::AbstractArray{T,5}, x2::AbstractArray{T,2},
                 n::Int, p1::Int, p2::Int, p3::Int, s1::Int, s2::Int,
                 s3::Int, d1::Int, d2::Int, d3::Int, mode::Int) where T
    Wx,Hx,Dx,Cx,Nx = size(x)
    Ww,Hw,Dw,C1,C2 = size(w)
    xn = x[:, :, :, :, n]
    im2col_3d!(xn,x2,Wx,Hx,Dx,Cx,Ww,Hw,Dw,p1,p2,p3,s1,s2,s3,d1,d2,d3,mode)
    return x2
end

function col2im3d!(w::AbstractArray{T,5}, x::AbstractArray{T,5}, x2::AbstractArray{T,2},
                 n::Int, p1::Int, p2::Int, p3::Int, s1::Int, s2::Int,
                 s3::Int, d1::Int, d2::Int, d3::Int, mode::Int) where T
    Wx,Hx,Dx,Cx,Nx = size(x)
    Ww,Hw,Dw,C1,C2 = size(w)
    xn = x[:, :, :, :, n]
    col2im_3d!(x2,xn,Wx,Hx,Dx,Cx,Ww,Hw,Dw,p1,p2,p3,s1,s2,s3,d1,d2,d3,mode)
    x[:, :, :, :, n] = xn
    return x
end

function conv_nd!{T}(y::AbstractArray{T}, x::AbstractArray{T}, w::AbstractArray{T};
                  padding=0, stride=1, mode=0, alpha=1)
    if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    inp_dim = size(x)
    kernel_dim = size(w)
    if inp_dim[end-1]!=kernel_dim[end-1]; throw(DimensionMismatch()); end
    out_dim = size(y)
    x2dims = im2col_dims(w,y)
    x2 = similar(x, x2dims)
    pad = psize(padding,x)
    strides = psize(stride,x)
    M,N,K,Y = prod(out_dim[1:end-2]),out_dim[end-1],prod(kernel_dim[1:end-1]),prod(out_dim[1:end-1])
    alpha,beta,yidx = T(alpha),T(0),1
    @inbounds for n in 1:inp_dim[end]
        im2colnd!(w, x, x2, n, pad, strides, mode)
        gemm!('N','N',M,N,K,alpha,pointer(x2),pointer(w),beta,pointer(y,yidx))
        yidx += Y
    end
    return y
end
function conv_nd_grad_w!{T}(dw::AbstractArray{T}, x::AbstractArray{T}, w::AbstractArray{T},
  dy::AbstractArray{T}; padding=0, stride=1, mode=0, alpha=1)
    # dw = x'*dy
    inp_dim = size(x)
    kernel_dim = size(w)
    dy_dim = size(dy)
    # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    # @assert Cx==C1 && Cy==C2 && Ny==Nx
    x2dims = im2col_dims(w,dy)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = prod(dy_dim[1:end-1]),prod(kernel_dim[1:end-1]),dy_dim[end-1],prod(dy_dim[1:end-2])
    alpha,beta = T(alpha),T(1)
    pad = psize(padding,x)
    strides = psize(stride,x)
    dyi = 1
    @inbounds for n in 1:inp_dim[end]
        im2colnd!(w, x, x2, n, pad, strides, mode)
        gemm!('T','N',M,N,K,alpha,pointer(x2),pointer(dy,dyi),beta,pointer(dw))
        dyi += Y
    end
    return dw
end

function conv_nd_grad_x!{T}(dx::AbstractArray{T}, x::AbstractArray{T}, w::AbstractArray{T},
  dy::AbstractArray{T}; padding=0, stride=1, mode=0, alpha=1)
   # dx = dy*w'
    inp_dim = size(x)
    kernel_dim = size(w)
    dy_dim = size(dy)
   # if mode != 0 && mode != 1; throw(ArgumentError("conv2d only supports mode=0 or 1.")); end
    @assert inp_dim[end-1]==kernel_dim[end-1] && dy_dim[end-1]==kernel_dim[end] &&
                            dy_dim[end]==inp_dim[end]

    x2dims = im2col_dims(w,dy)
    x2 = similar(x, x2dims)
    # op(A) is an m-by-k matrix, op(B) is a k-by-n matrix, C is an m-by-n matrix.
    Y,M,N,K = prod(dy_dim[1:end-1]),prod(dy_dim[1:end-2]),prod(kernel_dim[1:end-1]),dy_dim[end-1]
    alpha,beta = T(alpha),T(0)
    pad = psize(padding,x)
    strides = psize(stride,x)
    dyi = 1
    @inbounds for n in 1:inp_dim[end]
        gemm!('N','T',M,N,K,alpha,pointer(dy,dyi),pointer(w),beta,pointer(x2))
        col2imnd!(w,dx,x2,n,pad,strides,mode)
        dyi += Y
    end
    return dx
end

function im2colnd!{T}(w::AbstractArray, x::AbstractArray, x2::AbstractArray{T,2},
                 n::Int, pad::AbstractArray, strides::AbstractArray, mode::Int)
    inp_dim = size(x)
    kernel_dim = size(w)
    img_size = prod(inp_dim[1:end-1])
    xn = reshape(x[img_size * (n - 1) + 1:img_size * n], inp_dim[1:end-1])
    im2col_nd!(xn,x2,kernel_dim,pad,strides,mode)
    return x2
end

function col2imnd!(w::AbstractArray{T}, x::AbstractArray{T}, x2::AbstractArray{T,2},
                 n::Int, pad::AbstractArray{Int}, strides::AbstractArray{Int}, mode::Int) where T
    inp_dim = size(x)
    kernel_dim = size(w)
    img_size = prod(inp_dim[1:end-1])
    xn = reshape(x[img_size * (n - 1) + 1:img_size * n], inp_dim[1:end-1])
    col2im_nd!(x2,xn,kernel_dim,pad,strides,mode)
    x[img_size * (n - 1) + 1:img_size * n] = xn[:]
    x = reshape(x, inp_dim)
    return x
end
