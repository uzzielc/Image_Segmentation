function [intV,vDepX,xGenV] = intVDependsOnX(V3,C,bounds)
%   [intV,vDepX,xGenV] = intVDependsOnX(V3,C,bounds)
%   
%   This function helps with getting the dependent vertices for each center
%   used to generate the voronoi diagram. This is useful in calculating the
%   gradients all at once.
%
% INPUTS:
%
%   V3: an array of size (M,2) of coordinates of vertices in the voronoi diagram
%       used by C.
%
%   C:  a cell array that holds the vertices that are dependent on the
%       points in X.
%       i.e. C{i} = [3,5,7] => [V3(3,1),V3(3,2)],[V3(5,1),V3(5,2)],[V3(7,1),V3(7,2)]
%       are dependent on X(i,:).
%
%   NOTE:  [V3,C] = voronoin(X). 
%
% OUTPUTS: 
%
%   intV: an array of size (K,2), where K is the number of interior
%         vertices in V3. The ith row of intV gives the x and y coordinates of
%         the ith interior vertex of the voronoi diagram.
%
%   vDepX: an array of size (K,3), where K is the number of interior vertices in V3,
%          whose rows are the indices of centers in X that generate a
%          vertex.
%   e.g.
%       if vDepX(i,:) = [1,6,8] then, intV(i,:) = [x_coord,y_coord] is
%       generated by X(1,:), X(6,:), X(8,:).
%
%   xGenV: a cell array of size (N,1), where N is the number of centers
%           used to generate the voronoi diagram. Each row in xGenV is a
%           list of indices for intV.
%
%   e.g.
%       if xGenV(3,:) = [1,2,3,7] then, the center X(3,:) generates the
%       vertices intV(1,:), intV(2,:), intV(3,:), and intV(7,:).
%
%


% Need to convert V3 into vertices that are in the boundary
% square.
% inpolygon fails in some cases!!!!
%IN = inpolygon(V3(:,1),V3(:,2),bounds,bounds);

mask = V3;
mask(mask > bounds(1) & mask < bounds(2))=1;
mask = sum(mask,2);
IN = mask == 2;
% get indices for vertices that are on the interior of the boudnary
int_indices = find(IN == 1);

% Get the number of centers used to generate the voronoi diagram
sz_C = size(C,1);
% Get the number of interior vertices in the voronoi diagram
sz_int_ind = size(int_indices,1);

% Initialize the output data structures.
vDepX = zeros(sz_int_ind,3);
intV = zeros(sz_int_ind,2);
xGenV1 =zeros(sz_C,sz_int_ind);

% Create a matrix out of the cells in C. (note this matrix is zero padded)
C_mat = cell2mat_pad(C);
C_mat_size = size(C_mat);
m = C_mat_size(1)*C_mat_size(2);

% create 3-D array where the ith matrix ( i.e. (:,:,i) ) is the same size
% as C_mat and every entry of this matrix is the interior index value whose
% dependencies we wish to find.
int_ind_mat = repmat(int_indices',m,1); 
int_ind_ndmat = reshape(int_ind_mat,C_mat_size(1),C_mat_size(2),length(int_indices));
% e.g.:
%   if int_indices = [5,7,8]' then
%   int_ind_ndmat(:,:,1) = 5*ones(C_mat_size)
%   int_ind_ndmat(:,:,2) = 7*ones(C_mat_size)
%   int_ind_ndmat(:,:,3) = 8*ones(C_mat_size)


% Get a logical 3-D array where entries of the ith matrix ( i.e. (:,:,i) )
% tell us which rows in C_mat hold index values that match int_indices(i)
% e.g. (continuing with example from above):
%   if C_mat = [12,5,7,0,0]
%              [1,5,6,12,0]
%              [1,2,3,5,7]
%              [1,2,3,7,12]
%
%   (int_ind_ndmat == C_mat)(:,:,1) = [0,1,0,0,0]
%                                     [0,1,0,0,0]
%                                     [0,0,0,1,0]
%                                     [0,0,0,0,0]
%   which tells us that V3(int_indices(1),:) = V3(5,:) is dependent on
%   the voronoi centers X(1,:), X(2,:), and X(3,:).
logical_ind = C_mat == int_ind_ndmat;

% sum the result along the columns
% (since were interested in which rows have a nonzero sum)
% this results in a 3-D array of size (sz_C,1,sz_int_ind)
logical_ind = sum(logical_ind,2);


% reshape the result into a matrix of size (sz_C,sz_int_ind), take the
% transpose in order to get the ith row to represent the dependences of the
% ith vertex on centers in X indexed by the column index of non zero
% entries.
% e.g. (continuing with example from above):
%
%   logical_ind(1,:) = [1,1,1,0] (from previous example)
%
%   logical_ind(2,:) = [1,0,1,1] (new example)
%
%   which tells us that V3(int_indices(1),:) = V3(5,:) is dependent on
%   the voronoi centers X(1,:), X(2,:), and X(3,:)
%   and that
%   V3(int_indices(2),:) = V3(7,:) is dependent on X(1,:), X(3,:), and X(4,:)
logical_ind = reshape(logical_ind,sz_C,sz_int_ind)';

% for each row, i.e. for each interior vertex,
% get the column index of non zero entries which represent dependencies
% and store them in vDepX.
% we also create xGenV1 which is used to create a cell array which
% tells us X(i,:) generates, or contributes, to which interior vertices.
for i = 1:length(int_indices)
    indx = int_indices(i);
    indices = find(logical_ind(i,:)==1);
    vDepX(i,:) = indices;
    zz = zeros(sz_C,1);
    zz(indices) = i;
    xGenV1(:,i) = zz;
    intV(i,:) = V3(indx,:);
end


xGenV = cell(size(C,1),1);
for i = 1:size(xGenV1,1)
   xGenV{i,1} = nonzeros(xGenV1(i,:));
end


    function C_mat = cell2mat_pad(C)
        row_size = max(cellfun(@(x)size(x,2),C)); % get max row size for padded matrix
        C_mat = zeros(row_size);
        for k = 1:size(C,1)
            C_mat(k,:) = [C{k}, zeros(1,row_size - size(C{k},2))];
        end
    end


end

%%%%% BELOW IS MY OLD IMPLEMENTATION WHICH WAS VERY SLOW. 
%%%%% LEFT HERE FOR POSSIBLE DEBUGGING IF NEW IMPLEMENTATION HAS ISSUES
%{
% for i = 1:length(int_indices)
%     indx = int_indices(i);
%     indices = cellfun(@(x)ismember(indx,x),C);
%     indices = find(indices == 1);
%     vDepX(i,:) = indices';
%     zz = zeros(size(C,1),1);
%     zz(indices) = i;
%     xGenV1 = [xGenV1,zz];
%     intV(i,:) = V3(indx,:);
% end

% NOTE: The nested for loop runs 2x faster than using cellfun.
%       The use of ismembc over ismember also results in increased
%       performance.
%       Logical indexing using the sum(C{j}==indx) yields even faster
%       performance than two methods above (about 1/40 of the time required
%       with no nested loops and cellfun)

% for i = 1:length(int_indices)
%     indx = int_indices(i);
%     for j = 1:size(C,1)
%         %indices(j) = ismember(indx,C{j}); SLOWER
%         %indices(j) = ismembc(indx,sort(C{j})); % FASTER
%         %indices(j) = sum(C{j}==indx); % 2nd FASTEST
%         indices(j) = nnz(C{j}==indx); % FASTEST
%     end
%     indices = find(indices == 1);
%     vDepX(i,:) = indices';
%     zz = zeros(size(C,1),1);
%     zz(indices) = i;
%     xGenV1 = [xGenV1,zz];
%     intV(i,:) = V3(indx,:);
% end
%}


