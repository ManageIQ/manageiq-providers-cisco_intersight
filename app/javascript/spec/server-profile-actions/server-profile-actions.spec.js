import React from 'react';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import fetchMock from 'fetch-mock';
import { renderWithRedux } from '@@spec-helpers/mountForm';

import ServerProfileActions from '../../components/server-profile-actions';

describe('ServerProfileActions', () => {
  const profilesUrl = '/api/physical_server_profiles?expand=resources&attributes=id,name';
  const serverUrl = '/api/physical_servers/42?attributes=assigned_server_profile.id';
  const postUrl = '/api/physical_server_profiles';

  let dispatchSpy;
  let addFlashSpy;
  let onModalClose;

  const renderActions = (action) => renderWithRedux(
    <ServerProfileActions onModalClose={onModalClose} modalData={{ action }} />,
  );

  const postedBody = () => JSON.parse(fetchMock.callHistory.lastCall(postUrl, { method: 'POST' }).options.body);

  const submitAssignForm = async() => {
    const user = userEvent.setup();
    await user.selectOptions(await screen.findByRole('combobox', { name: 'Server Profile' }), 'profile-b');
    const call = dispatchSpy.mock.calls.find(([action]) => action.type === 'FormButtons.callbacks');
    await waitFor(() => { call[0].payload.saveClicked(); });
  };

  beforeAll(() => {
    fetchMock.mockGlobal();
  });

  beforeEach(() => {
    ManageIQ.record.recordId = 42;
    onModalClose = jest.fn();
    dispatchSpy = jest.spyOn(ManageIQ.redux.store, 'dispatch');
    addFlashSpy = jest.spyOn(window, 'add_flash').mockImplementation(() => true);
  });

  afterEach(() => {
    ManageIQ.record.recordId = null;
    dispatchSpy.mockRestore();
    addFlashSpy.mockRestore();
    fetchMock.removeRoutes();
    fetchMock.callHistory.clear();
  });

  describe('assign_server', () => {
    beforeEach(() => {
      fetchMock.get(profilesUrl, {
        resources: [{ id: '1', name: 'profile-a' }, { id: '2', name: 'profile-b' }],
      });
    });

    it('loads the server profiles and renders the select', async() => {
      renderActions('assign_server');

      const select = await screen.findByRole('combobox', { name: 'Server Profile' });
      expect(select).toBeInTheDocument();
      expect(fetchMock.callHistory.called(profilesUrl)).toBe(true);
      await waitFor(() => {
        expect(screen.getByRole('option', { name: 'profile-a' })).toBeInTheDocument();
        expect(screen.getByRole('option', { name: 'profile-b' })).toBeInTheDocument();
      });
      expect(onModalClose).not.toHaveBeenCalled();
    });

    it('initializes the form buttons', async() => {
      renderActions('assign_server');

      await waitFor(() => {
        expect(dispatchSpy).toHaveBeenCalledWith({
          type: 'FormButtons.init',
          payload: { saveable: true },
        });
        expect(dispatchSpy).toHaveBeenCalledWith({
          type: 'FormButtons.customLabel',
          payload: 'Assign',
        });
        expect(dispatchSpy).toHaveBeenCalledWith({
          type: 'FormButtons.callbacks',
          payload: { saveClicked: expect.any(Function) },
        });
      });
    });

    it('posts the selected profile and flashes the results', async() => {
      fetchMock.postOnce(postUrl, { results: [{ success: true, message: 'Assigned' }] });
      renderActions('assign_server');

      await submitAssignForm();

      await waitFor(() => expect(fetchMock.callHistory.called(postUrl, { method: 'POST' })).toBe(true));
      expect(postedBody()).toEqual({
        action: 'assign_server',
        resources: [{ id: '2', server_id: 42 }],
      });
      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Assigned', 'success'));
    });

    it('flashes an error result', async() => {
      fetchMock.postOnce(postUrl, { results: [{ success: false, message: 'Cannot assign' }] });
      renderActions('assign_server');

      await submitAssignForm();

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Cannot assign', 'error'));
    });

    it('flashes the API error message when the request fails', async() => {
      fetchMock.postOnce(postUrl, { status: 400, body: { error: { message: 'Bad request' } } });
      renderActions('assign_server');

      await submitAssignForm();

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Bad request', 'error'));
    });

    it('waits for the task and flashes its message', async() => {
      const waitForTask = jest.spyOn(API, 'wait_for_task').mockResolvedValue({ message: 'Task done' });
      fetchMock.postOnce(postUrl, { results: [{ success: true, message: 'Queued', task_id: '7' }] });
      renderActions('assign_server');

      await submitAssignForm();

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Task done', 'success'));
      expect(waitForTask).toHaveBeenCalledWith('7');
      expect(addFlashSpy).toHaveBeenCalledWith('Queued', 'success');
      waitForTask.mockRestore();
    });

    it('flashes an error when the task fails', async() => {
      const waitForTask = jest.spyOn(API, 'wait_for_task').mockRejectedValue({ message: 'Task exploded' });
      fetchMock.postOnce(postUrl, { results: [{ success: true, message: 'Queued', task_id: '7' }] });
      renderActions('assign_server');

      await submitAssignForm();

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Task exploded', 'error'));
      waitForTask.mockRestore();
    });
  });

  describe.each(['deploy_server', 'unassign_server'])('%s', (action) => {
    it('closes the modal and flashes an error when no profile is assigned', async() => {
      fetchMock.get(serverUrl, { id: '42' });
      renderActions(action);

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith(
        'No server profile is assigned to server with ID 42',
        'error',
      ));
      expect(onModalClose).toHaveBeenCalledTimes(1);
      expect(fetchMock.callHistory.called(postUrl, { method: 'POST' })).toBe(false);
    });

    it('posts the action for the assigned profile and flashes the result', async() => {
      fetchMock.get(serverUrl, { id: '42', assigned_server_profile: { id: '9' } });
      fetchMock.postOnce(postUrl, { results: [{ success: true, message: 'Done' }] });
      renderActions(action);

      await waitFor(() => expect(fetchMock.callHistory.called(postUrl, { method: 'POST' })).toBe(true));
      expect(postedBody()).toEqual({ action, resources: [{ id: '9' }] });
      expect(onModalClose).toHaveBeenCalledTimes(1);
      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Done', 'success'));
    });

    it('does not flash when the response has no results', async() => {
      fetchMock.get(serverUrl, { id: '42', assigned_server_profile: { id: '9' } });
      fetchMock.postOnce(postUrl, { results: [] });
      renderActions(action);

      await waitFor(() => expect(fetchMock.callHistory.called(postUrl, { method: 'POST' })).toBe(true));
      expect(addFlashSpy).not.toHaveBeenCalled();
    });

    it('flashes the API error message when fetching the server fails', async() => {
      fetchMock.get(serverUrl, { status: 500, body: { error: { message: 'Server exploded' } } });
      renderActions(action);

      await waitFor(() => expect(addFlashSpy).toHaveBeenCalledWith('Server exploded', 'error'));
      expect(fetchMock.callHistory.called(postUrl, { method: 'POST' })).toBe(false);
    });
  });
});
