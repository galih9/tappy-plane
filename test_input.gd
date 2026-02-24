extends SceneTree
func _init():
    print("Methods in Input:")
    for m in Input.get_method_list():
        if "cursor" in m.name.to_lower():
            print(m.name)
    print("Methods in DisplayServer:")
    for m in DisplayServer.get_method_list():
        if "cursor" in m.name.to_lower():
            print(m.name)
    quit()
