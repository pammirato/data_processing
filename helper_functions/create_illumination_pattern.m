function [pattern] = create_illumination_patter(inputImage, xCenter,yCenter,minIntensity, ...
                                                maxIntensity, radius)
%https://www.mathworks.com/matlabcentral/newsreader/view_thread/253588 

  [rows, columns, numberOfColorBands] = size(inputImage);
  pattern = zeros(rows, columns);
  for row = 1 : rows
    for col = 1 : columns
      dy = row - yCenter;
      dx = col - xCenter;
      pattern(row, col) = minIntensity + (maxIntensity -minIntensity) ...
                                       * exp(-(1/2)*(dx*dx + dy*dy)/ radius);
    end%for col
  end%for row
end
