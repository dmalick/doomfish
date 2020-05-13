


@enum Clickability begin
    # the sprite is clickable everywhere regardless of appearance.
    EVERYWHERE
    # the sprite is clickable nowhere. it is skipped. useful for eg mouse cursor sprite
    NOWHERE
    # the sprite is clickable iff the location it is clicked on isn't "transparent enough"
    #  ... definition of "enough" is in ColorSample#isTransparentEnough
    TRANSPARENCY_BASED
end
