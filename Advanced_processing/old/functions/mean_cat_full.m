function [x,m,e]=mean_cat_full(a,dim,cats)

% computes mean and sem of a along dimension dim, grouped first by category
% cats

if dim == 2
    a=a';
end

fnan=find(all(~isnan(a),2));
a=a(fnan,:);
cats=cats(fnan);

u=unique(cats);

x=zeros(length(u),size(a,2));
for ii=1:length(u)
    x(ii,:)=mean(a(find(cats==u(ii)),:),1);
end

m=mean(x,1);
e=std(x,[],1)/sqrt(length(u));