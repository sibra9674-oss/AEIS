// Port of NSV13 tgui/interfaces/MunitionsTrolley.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { Fragment } from 'react';
// NSV13

import { useBackend, useLocalState } from '../backend';
import { Button, Section } from 'tgui-core/components';
import { Window } from '../layouts';

export const MunitionsTrolley = (props: any) => {
  const { act, data } = useBackend<any>();
  return (
    <Window resizable theme="hackerman">
      <Window.Content scrollable>
        <Section title="Loaded" buttons={
          <Button
            content="Unload All"
            icon="eject"
            onClick={() => act('unload_all')} />
        }>
          {Object.keys(data.loaded).map(key => {
            let value = data.loaded[key];
            return (
              <Fragment key={key}>
                <Button
                  content={`Unload ${value.name}`}
                  icon="arrow-right"
                  onClick={() => act('unload', { id: value.id })} />
              </Fragment>);
          })}
        </Section>
      </Window.Content>
    </Window>
  );
};
