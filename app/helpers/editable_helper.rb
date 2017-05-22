module EditableHelper
  def updated_at_by(editable)
    return {} unless editable.is_edited?

    {
      updated_at: editable.updated_at,
      updated_by: {
        name: editable.last_edited_by.name,
        path: user_path(editable.last_edited_by)
      }
    }
  end
end
