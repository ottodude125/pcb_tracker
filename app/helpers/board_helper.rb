module BoardHelper

=begin
  def list_revisions(board)

    # Get the list of designs for the board.
    designs = board.designs

    if designs.size == 0
      return "None"
    else
      revisions = Array.new
      for design in designs
        if design.design_type == 'New'
          revisions.push(Revision.find(design.revision_id).name)
        elsif design.design_type == 'Date Code'
          revisions.push(Revision.find(design.revision_id).name +
                         design.numeric_revision.to_s +
                         '_eco' +
                         design.eco_number)
        elsif design.design_type == 'Dot Rev'
          revisions.push(Revision.find(design.revision_id).name +
                         design.numeric_revision.to_s)
        end
      end
      revisions.sort!
      return revisions.join(', ')
    end
  end

=end
end
