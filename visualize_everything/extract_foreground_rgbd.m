% GrabCut implementation supporting RGBD images
function trimap = extract_foreground_rgbd(img, bbox)
    plotfig = gcf;

    warning('off','all');

    % initialize trimap with all pixels outside of bounding box marked background
    fixedBG = img;
    fixedBG(bbox(2):bbox(2)+bbox(4), bbox(1):bbox(1)+bbox(3), :) = 0;
    fixedBG = sum(fixedBG, 3);
    fixedBG = logical(fixedBG);

    imd = double(img);

    % compute Beta parameter for GrabCut algorithm
    Beta = compute_beta(imd);

    k = 5; % recommended setting for k parameter (GMM components)
    G = 50; % recommended setting for Gamma parameter
    maxIter = 1;
    diffThreshold = 0.001;

    trimap = GCAlgo(imd, fixedBG, k, G, maxIter, Beta, diffThreshold, []);
    trimap = double(1 - trimap).*3;
end

function beta = compute_beta(img)
    beta = 0;
    [m,n] = size(img);

    for y=1:m
        for x=1:n

            rgbd = img(y,x);

            if x > 1 % include pixel to left
                beta = beta + norm(rgbd - img(y,x-1));

                if y > 1 % include pixel to upper left
                    beta = beta + norm(rgbd - img(y-1,x-1));
                end
            end
            if y > 1 % include pixel above
                beta = beta + norm(rgbd - img(y-1,x));

                if x < n % include pixel to upper right
                    beta = beta + norm(rgbd - img(y-1,x+1));
                end
            end
        end
    end

    beta = 1 / (2 * beta / (4*m*n - 3*m - 3*n + 2));
end
