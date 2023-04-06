module balltracker

using Images, VideoIO, ImageDraw, ImageView

"""
    extract_coordinates(img::AbstractMatrix; rad = 8)

Find coordinates of a green ball in an image.
"""
function extract_coordinates(img::AbstractMatrix; rad = 8)
    preimg = map(img) do pixel
        hsv = HSV(pixel)
        (0.2 < hsv.s < 0.8) && (40 < hsv.h < 150) ? Gray(hsv.v) : Gray(zero(hsv.v))
    end
    blobs = Images.blob_LoG(preimg, [rad], rthresh = 0.5)
    ballblob = argmax(b->b.amplitude, blobs)
    ballblob.location
end


"""
    track_ball(cam; fps = 30, ballradius = 8, markerradius = 8, markercolor = RGB(1, 0, 0), duration = 5, callback = display, downsampling = 2, sleep = sleep)

Track a ball in a video stream.

# Arguments:
- `cam`: An object that iterates images when calling `read(cam)`, e.g., `VideoIO.openvideo(path)` or `VideoIO.opencamera()`.
- `fps`: Frames per second to track the ball at.
- `ballradius`: Radius of blobs to detect. A larger radius is more computaionally expensive.
- `markerradius`: To indicate the found ball
- `markercolor`: To indicate the found ball
- `duration`: Maximum duration to track the ball for (seconds).
- `callback`: a function taking an image and does something interesting.
- `downsampling`: An integer specifying a downsampling factor for the image before blob detection.
- `sleep`: The function used to sleep, alternatives include `Libc.systemsleep`
"""
function track_ball(cam;
        fps = 30,
        ballradius = 8,
        markerradius = 8,
        markercolor = RGB(1,0,0),
        duration = 5,
        callback = display,
        downsampling = 2,
        sleep = sleep,
    )

    errs = 0
    i = 1
    while !eof(cam)
        i > duration*fps && break
        errs >= 10 && break
        execution_time = @elapsed try
            img = read(cam)
            coords = extract_coordinates(img[1:downsampling:end, 1:downsampling:end]; rad=ballradius)
            draw!(img, ImageDraw.CirclePointRadius(downsampling*coords, markerradius),markercolor)
            callback(img)
            errs = 0
        catch e
            errs += 1
            @error e
        end
        sleep(max(0, 1/fps-execution_time))
        i += 1
    end
end

"""
    julia_main()

Launches [`track_ball`](@ref) with ImageView as display.
"""
function julia_main()::Cint
    isempty(ARGS) && error("No arguments given, please provide the path to an interesting video file")
    path = ARGS[1]
    cam = VideoIO.openvideo(path)

    img = first(cam)
    canvas = imshow(img)
    displayfun = img -> imshow!(canvas["gui"]["canvas"],img);

    track_ball(cam; duration=3, fps=30, callback=displayfun, downsampling=8)
    0
end

end # module balltracker
