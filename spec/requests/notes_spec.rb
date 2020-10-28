# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/notes', type: :request do
  let!(:notebook_1) { FactoryBot.create(:notebook) }
  let!(:notebook_2) { FactoryBot.create(:notebook) }

  let!(:note_1) { FactoryBot.create(:note, notebook: notebook_1, contents: 'Note 1') }
  let!(:note_2) { FactoryBot.create(:note, notebook: notebook_2, contents: 'Note 2') }

  let(:valid_attributes) { FactoryBot.attributes_for(:note, notebook: notebook_1, contents: 'New Note') }
  let(:invalid_attributes) { FactoryBot.attributes_for(:note, contents: nil) }

  # This should return the minimal set of values that should be in the headers
  # in order to pass any filters (e.g. authentication) defined in
  # NotesController, or in your router and rack
  # middleware. Be sure to keep this updated too.
  let(:valid_headers) do
    {}
  end

  describe 'GET /index' do
    it 'scopes response to currently viewed notebook' do
      get notebook_notes_url(notebook_1), headers: valid_headers, as: :json

      expect(response).to be_successful
      expect(response.body).to include(note_1.contents)
      expect(response.body).not_to include(note_2.contents)
      expect(response.body).not_to include(valid_attributes[:contents])
    end
  end

  describe 'GET /show' do
    it 'renders a successful response when note is linked to given notebook' do
      get notebook_note_url(notebook_1, note_1), as: :json

      expect(response).to be_successful
      expect(response.body).to include(note_1.contents)
      expect(response.body).not_to include(note_2.contents)
      expect(response.body).not_to include(valid_attributes[:contents])
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Note' do
        expect do
          post notebook_notes_url(notebook_1),
               params: valid_attributes, headers: valid_headers, as: :json
        end.to change(notebook_1.notes, :count).by(1)
      end

      it 'renders a JSON response with the new note' do
        post notebook_notes_url(notebook_1),
             params: valid_attributes, headers: valid_headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))

        expect(response.body).not_to include(note_1.contents)
        expect(response.body).not_to include(note_2.contents)
        expect(response.body).to include(valid_attributes[:contents])
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Note' do
        expect do
          post notebook_notes_url(notebook_1),
               params: invalid_attributes, as: :json
        end.to change(Note, :count).by(0)
      end

      it 'renders a JSON response with errors for the new note' do
        post notebook_notes_url(notebook_1),
             params: invalid_attributes, headers: valid_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')

        expect(response.body).to include('Contents can\'t be blank')
        expect(response.body).to include('Contents is too short (minimum is 5 characters)')
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys only the requested note' do
      expect do
        delete notebook_note_url(notebook_1, note_1), headers: valid_headers, as: :json
      end.to change(Note, :count).by(-1)
    end
  end
end