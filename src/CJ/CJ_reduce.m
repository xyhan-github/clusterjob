function C = CJ_reduce(A,B)
% This function reduces the contents of mapped A, and B
% through CJ. A and B are different instances of cj parrun

% CHECK A, and B of of the same class and size
if( ~check(A,B) ) ; error('   CJerr::A, and B are of different size or class'); end;


if(     isa(A,'double') )
C = reduce_double(A,B);

elseif( isa(A, 'cell'))  % double or char
C = reduce_cell(A,B);

elseif( isa(A,'struct') )

C = reduce_struct(A,B);

else
error('   CJerr::Not implemeneted yet');
end



end  %CJ_reduce

function c = reduce_struct(a,b)

% make a and b same size and class if
% they are empty
if(isempty(a) && isstruct(b))
    vfields = fields(b);
    for i = 1:length(vfields)
    field = vfields{i};
    a.(field) = [];
    end

elseif(isempty(b) && isstruct(a))

    vfields = fields(a);
    for i = 1:length(vfields)
    field = vfields{i};
    b.(field) = [];
    end

elseif(isempty(b) && isempty(a))
    c = [];
    return;
end



flds = fields(a);
for j = 1:length(flds)
    if( isa(a.(flds{j}),'double') )
    c.(flds{j}) = reduce_double( a.(flds{j}) , b.(flds{j}) );
    elseif(isa(a.(flds{j}),'char') )
    c.(flds{j}) = reduce_char( a.(flds{j}) , b.(flds{j}) );
    elseif( isa(a.(flds{j}),'cell')  )
    c.(flds{j}) = reduce_cell( a.(flds{j}) , b.(flds{j}) );
    elseif( isa(a.(flds{j}),'strcut')  )
    c.(flds{j}) = reduce_structure( a.(flds{j}) , b.(flds{j}) );
    else
    error('   CJerr:: class %s is not recognized', class(A.(flds{j})) );
    end
end


end


function c = reduce_cell(a,b);

if( ~check(a,b) ) ; error('   CJerr::a, and b are of different size or class'); end;

if(  isequaln(a,b) )
c = a;
return;
end

w_char   = cellfun( @(x) isa(x,'char') , a, 'UniformOutput', false );
w_double = cellfun( @(x) isa(x,'char') , a, 'UniformOutput', false );
w_struct = cellfun( @(x) isa(x,'struct') , a, 'UniformOutput', false );
w_cell   = cellfun( @(x) isa(x,'cell') , a, 'UniformOutput', false );

if(sum([w_char{:}]) > 0)            % if we find one character
     c = cellfun( @reduce_char   , a, b, 'UniformOutput', false );
elseif(sum([w_double{:}]) > 0)      % we we find one double
     c = cellfun( @reduce_double , a, b, 'UniformOutput', false );
elseif(sum([w_struct{:}]) > 0)      % we we find one structure
     c = cellfun( @reduce_struct , a, b, 'UniformOutput', false );
elseif(sum([w_cell{:}]) > 0)        % we we find one cell in our cell array
     c = cellfun( @reduce_cell   , a, b, 'UniformOutput', false );

end

end  %reduce_cell







function c = reduce_double(a,b)

if(  isequaln(a,b) )
c = a;
return;
end

% check if the class of elements is double
if(~ strcmp( class(a) , 'double') ); error('   CJerr::Beyond the scope of CJ at the moment. Cells must contain double or char class variables'); end
if(~ strcmp( class(b) , 'double') ); error('   CJerr::Beyond the scope of CJ at the moment. Cells must contain double or char class variables'); end


A = num2cell(a);
B = num2cell(b);

if(isempty(A))
A = cell(size(B));
elseif(isempty(B))
B = cell(size(A));
end





function z = myAdd(x,y)
if ( isempty(x) || isnan(x)     )
z = y;
elseif ( isempty(y) || isnan(y)     )
z = x;
else
z = x+y;
end
end

C = cellfun( @myAdd , A, B, 'UniformOutput', false );

c = cell2mat(C);

end %reduce_double







function c = reduce_char(a,b)

if(  isequaln(a,b) )
c = a;
return;
end

% check if the class of elements is double
if(~ (strcmp( class(a) , 'char') || strcmp( class(a) , 'double') ) );
error('   CJerr::Beyond the scope of CJ at the moment. Cells must contain double or char class variables');
end
if(~ (strcmp( class(b) , 'char') || strcmp( class(b) , 'double') ) );
error('   CJerr::Beyond the scope of CJ at the moment. Cells must contain double or char class variables');
end

if ( isempty(a) || sum(any(isnan(a)))==prod(size(a))      )
c = b;
elseif( isempty( b )  || sum(any(isnan(b)))==prod(size(b))  )
c = a;
else
error('   CJerr:: Sorry, I dont know how to reduce them!');
end


end %reduce_char












% Check
function c = check(A,B)
c = true;
if( ~ strcmp(class(A), class(B)) ); c = false ;end;
if( length(size(A)) ~= length(size(B))); c = false;end;

for i = 1:length(size(A))
if(size(A,i)~=size(B,i)); c = false; end;
end

end %check