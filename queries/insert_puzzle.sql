insert into Puzzle (
    puzzle_id,
    pieces,
    name,
    link,
    description,
    bg_color,
    owner,
    queue,
    status,
    m_date,
    permission) values
    (:puzzle_id,
    :pieces,
    :name,
    :link,
    :description,
    :bg_color,
    :owner,
    :queue,
    :status,
    datetime('now'),
    :permission);
