insert or ignore into Piece (
    id,
    x,
    y,
    r,
    w,
    h,
    b,
    adjacent,
    rotate,
    row,
    col,
    status,
    parent,
    puzzle
) values (
    :id,
    :x,
    :y,
    :r,
    :w,
    :h,
    :b,
    :adjacent,
    :rotate,
    :row,
    :col,
    :status,
    :parent,
    :puzzle
);
