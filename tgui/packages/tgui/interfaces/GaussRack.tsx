// Port of NSV13 tgui/interfaces/GaussRack.js (Inferno) to TGMC React/TS. Mechanical conversion, not compiled.
import { Fragment } from 'react';
// NSV13

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, ProgressBar } from 'tgui-core/components';
import { Window } from '../layouts';

export const GaussRack = (props: any) => {
  const { act, data } = useBackend<any>();
  return (
    <Window
     
      width={560}
      height={600}>
      <Window.Content scrollable>
        <Section>
          <Section title="Controls:">
            <Button
              fluid
              content="Load ammunition into gun"
              icon="arrow-circle-up"
              disabled={data.loading}
              onClick={() => act('load')} />
            <Button
              fluid
              content="Unload all ammunition from rack"
              icon="exclamation-triangle"
              color={"average"}
              onClick={() => act('unload_all')} />
          </Section>
          <Section title="Loaded ammunition:">
            <ProgressBar
              value={(data.capacity/data.max_capacity * 100)* 0.01}
              ranges={{
                good: [0.5, Infinity],
                average: [0.15, 0.5],
                bad: [-Infinity, 0.15],
              }} />
            <br />
            {Object.keys(data.bullets_info).map(key => {
              let value = data.bullets_info[key];
              return (
                <Fragment key={key}>
                  <Button
                    fluid
                    content={`Unload ${value.name}`}
                    icon="eject"
                    onClick={() => act('unload', { id: value.id })} />
                </Fragment>);
            })}
          </Section>
        </Section>
      </Window.Content>
    </Window>
  );
};
