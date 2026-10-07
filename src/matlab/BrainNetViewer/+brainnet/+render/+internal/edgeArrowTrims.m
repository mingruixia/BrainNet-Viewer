function [trimA,trimB,arrowLength]=edgeArrowTrims(lengths,nodeRadiusA,nodeRadiusB,edgeRadii,lengthScale)
%EDGEARROWTRIMS Shared tube/arrow placement; the tube ends at the cone base.
trimA=nodeRadiusA;
trimB=nodeRadiusB;
overlap=trimA+trimB>=0.9*lengths;
trimA(overlap)=0.05*lengths(overlap);
trimB(overlap)=0.05*lengths(overlap);
arrowLength=zeros(size(lengths),'like',lengths);
if lengthScale>0
    requested=lengthScale.*min(0.20.*lengths,max(1.5,5.*edgeRadii));
    available=max(0,0.9.*lengths-trimA-trimB);
    arrowLength=min(requested,min(0.35.*lengths,available));
end
end
