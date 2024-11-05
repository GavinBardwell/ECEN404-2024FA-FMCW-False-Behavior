function draggable_scatter_plot
    % Create figure and axis for the scatter plot
    fig = figure('Name', 'Interactive Scatter Plot', 'NumberTitle', 'off', 'WindowButtonDownFcn', @add_point);
    ax = axes(fig);
    hold(ax, 'on');
    xlim(ax, [0 10]);
    ylim(ax, [0 10]);
    title(ax, 'Click to Add Points, Drag to Move');
    xlabel(ax, 'X-axis');
    ylabel(ax, 'Y-axis');

    % Data storage for points
    data = struct('x', [], 'y', [], 'graphics', []);

    % Callback function to add points
    function add_point(~, ~)
        click_point = get(ax, 'CurrentPoint');
        x = click_point(1, 1);
        y = click_point(1, 2);
        % Add a new point if clicked within limits
        if x >= ax.XLim(1) && x <= ax.XLim(2) && y >= ax.YLim(1) && y <= ax.YLim(2)
            h = scatter(ax, x, y, 'filled', 'MarkerEdgeColor', 'k', 'ButtonDownFcn', @start_dragging);
            data.x = [data.x; x];
            data.y = [data.y; y];
            data.graphics = [data.graphics; h];
        end
    end

    % Variables for dragging
    dragging = false;
    current_graphic = [];

    % Start dragging callback
    function start_dragging(src, ~)
        dragging = true;
        current_graphic = src;
        % Set figure callbacks for dragging
        set(fig, 'WindowButtonMotionFcn', @dragging_point);
        set(fig, 'WindowButtonUpFcn', @stop_dragging);
    end

    % Dragging callback
    function dragging_point(~, ~)
        if dragging
            % Get new cursor position
            new_point = get(ax, 'CurrentPoint');
            new_x = new_point(1, 1);
            new_y = new_point(1, 2);
            % Update point position if within limits
            if new_x >= ax.XLim(1) && new_x <= ax.XLim(2) && new_y >= ax.YLim(1) && new_y <= ax.YLim(2)
                set(current_graphic, 'XData', new_x, 'YData', new_y);
            end
        end
    end

    % Stop dragging callback
    function stop_dragging(~, ~)
        dragging = false;
        % Remove figure callbacks for dragging
        set(fig, 'WindowButtonMotionFcn', '');
        set(fig, 'WindowButtonUpFcn', '');
        current_graphic = [];
    end
end
