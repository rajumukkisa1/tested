# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Group issue boards' do
      let(:board_1) { 'Upstream 1' }
      let(:board_2) { 'Upstream 2' }
      let(:board_3) { 'Upstream 3' }

      let(:group) do
        QA::Resource::Group.fabricate_via_api!
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        create_group_board(board_1)
        create_group_board(board_2)
        create_group_board(board_3)

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_group(group.path)
        end
        EE::Page::Group::Menu.perform(&:go_to_issue_boards)
      end

      it 'shows multiple group boards in the boards dropdown menu' do
        EE::Page::Group::Issue::Board::Show.perform do |show|
          show.click_boards_dropdown_button

          expect(show.boards_dropdown_content).to have_content(board_1)
          expect(show.boards_dropdown_content).to have_content(board_2)
          expect(show.boards_dropdown_content).to have_content(board_3)
        end
      end

      def create_group_board(name)
        QA::EE::Resource::Board::GroupBoard.fabricate_via_api! do |group_board|
          group_board.group = group
          group_board.name = name
        end
      end
    end
  end
end
