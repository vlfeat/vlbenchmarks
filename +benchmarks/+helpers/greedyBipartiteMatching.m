% GREEDYBIPARTITEMATCHING Compute greedy bipartite matching
%   M = greedyBipartiteMatching(NUM_A_NODES,NUM_B_NODES,EDGES)
%   Calculates bipartite matching between two sets of nodes 
%   A = {1,...,NUM_A_NODES} and B = {1,...,NUM_B_NODES} based on 
%   the sorted list of edges EDGES.   
%
%   EDGES array has got two columns where each row [a b] defines
%   edge between node a \in A and b \in B. Returns matching M which 
%   is array of size [1,numNodesA] and M(a) = b means that node a was 
%   matched to node b. If node a was not matched, M(a) = 0.
%
%   Algorithm basically goes sequentially through the EDGES and 
%   matches all vertices which has not been matched yet. Therefore
%   the ranked list of EDGES represents edge weighting.

% Author: Karel Lenc

% AUTORIGHTS