function R = colorization(I, D)
  imgNoise = (D == 0 | D == 10);

  maxImgAbsDepth = max(D(~imgNoise));
  D = D ./ maxImgAbsDepth;
  D(D > 1) = 1;
  
  assert(ndims(D) == 2);
  [H, W] = size(D);
  numPix = H * W;
  
  indsM = reshape(1:numPix, H, W);
  
  knownValMask = ~imgNoise;
  
  grayImg = rgb2gray(I);

  winRad = 1;
  
  len = 0;
  absImgNdx = 0;
  cols = zeros(numPix * (2*winRad+1)^2,1);
  rows = zeros(numPix * (2*winRad+1)^2,1);
  vals = zeros(numPix * (2*winRad+1)^2,1);
  gvals = zeros(1, (2*winRad+1)^2);

  for j = 1 : W
    for i = 1 : H
      absImgNdx = absImgNdx + 1;
      
      nWin = 0; % Counts the number of points in the current window.
      for ii = max(1, i-winRad) : min(i+winRad, H)
        for jj = max(1, j-winRad) : min(j+winRad, W)
          if ii == i && jj == j
            continue;
          end

          len = len+1;
          nWin = nWin+1;
          rows(len) = absImgNdx;
          cols(len) = indsM(ii,jj);
          gvals(nWin) = grayImg(ii, jj);
        end
      end

      curVal = grayImg(i, j);
      gvals(nWin+1) = curVal;
      c_var = mean((gvals(1:nWin+1)-mean(gvals(1:nWin+1))).^2);

      csig = c_var*0.6;
      mgv = min((gvals(1:nWin)-curVal).^2);
      if csig < (-mgv/log(0.01))
        csig=-mgv/log(0.01);
      end
      
      if csig < 0.000002
        csig = 0.000002;
      end

      gvals(1:nWin) = exp(-(gvals(1:nWin)-curVal).^2/csig);
      gvals(1:nWin) = gvals(1:nWin) / sum(gvals(1:nWin));
      vals(len-nWin+1 : len) = -gvals(1:nWin);

      % Now the self-reference (along the diagonal).
      len = len + 1;
      rows(len) = absImgNdx;
      cols(len) = absImgNdx;
      vals(len) = 1;
    end
  end

  vals = vals(1:len);
  cols = cols(1:len);
  rows = rows(1:len);
  A = sparse(rows, cols, vals, numPix, numPix);
   
  rows = 1:numel(knownValMask);
  cols = 1:numel(knownValMask);
  vals = knownValMask(:);
  G = sparse(rows, cols, vals, numPix, numPix);
 
  newVals = (A + G) \ double((vals .* D(:)));
  newVals = reshape(newVals, [H, W]);
  
  R = newVals * maxImgAbsDepth;
end
